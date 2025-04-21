const std = @import("std");
const io = std.io;
const mem = std.mem;
const testing = std.testing;
const Allocator = mem.Allocator;

// --- Core Interfaces (Aliases) ---
pub const Reader = io.Reader;
pub const Writer = io.Writer;
pub const Closer = io.Closer; // Assuming a struct with a close() method
pub const Seeker = io.SeekableStream; // Zig's SeekableStream combines seeking and stream

// --- Seek Constants ---
pub const SeekStart = io.SeekableStream.SeekMode.Start;
pub const SeekCurrent = io.SeekableStream.SeekMode.Current;
pub const SeekEnd = io.SeekableStream.SeekMode.End;

// --- Common Errors ---
pub const EOF = error.EndOfStream; // Alias for common end-of-stream error
pub const ErrUnexpectedEOF = error.UnexpectedEndOfStream; // From std.io
pub const ErrShortWrite = error.ShortWrite; // Custom error, similar to Go

// --- Helper Functions (Aliases/Wrappers) ---

/// Copies from src to dst until either EOF is reached on src or an error occurs.
/// It returns the number of bytes copied and the first error encountered.
pub const copy = io.copy;
pub const copyBuffer = io.copyBuffer;

/// Reads all bytes from r until EOF or error.
pub const readAll = io.readAllAlloc; // Requires allocator

/// Writes the string s to w.
pub const writeString = io.writeString;

/// Returns a Reader that reads from r but stops with EOF after n bytes.
pub fn LimitReader(reader: Reader, n: u64) LimitReaderImpl {
    return LimitReaderImpl{ .reader = reader, .remaining = n };
}

pub const LimitReaderImpl = struct {
    reader: Reader,
    remaining: u64,

    pub const ReadError = Reader.ReadError;

    pub fn read(self: *LimitReaderImpl, buf: []u8) ReadError!usize {
        if (self.remaining == 0) {
            return error.EndOfStream;
        }

        var limit = buf.len;
        if (@as(u64, limit) > self.remaining) {
            limit = @intCast(self.remaining);
        }

        const bytes_read = try self.reader.read(buf[0..limit]);
        self.remaining -= bytes_read;
        return bytes_read;
    }

    pub fn asReader(self: *LimitReaderImpl) Reader {
        return .{ .context = self, .readFn = read };
    }
};

/// Returns a Reader that writes to w what it reads from r.
pub fn TeeReader(reader: Reader, writer: Writer) TeeReaderImpl {
    return TeeReaderImpl{ .reader = reader, .writer = writer };
}

pub const TeeReaderImpl = struct {
    reader: Reader,
    writer: Writer,

    pub const ReadError = Reader.ReadError || Writer.WriteError;

    pub fn read(self: *TeeReaderImpl, buf: []u8) ReadError!usize {
        const bytes_read = try self.reader.read(buf);
        if (bytes_read > 0) {
            // Ignore short writes from the tee for simplicity, like Go's TeeReader
            _ = try self.writer.writeAll(buf[0..bytes_read]);
        }
        return bytes_read;
    }

    pub fn asReader(self: *TeeReaderImpl) Reader {
        return .{ .context = self, .readFn = read };
    }
};

/// Creates a writer that duplicates its writes to all the provided writers.
pub const multiWriter = io.multiWriter;

// --- Buffered I/O (bufio equivalents) ---

pub const BufferedReader = io.BufferedReader(4096, Reader); // Default size 4k
pub const BufferedWriter = io.BufferedWriter(4096, Writer); // Default size 4k

/// Creates a new BufferedReader wrapping the given reader.
pub fn newReader(reader: Reader) BufferedReader {
    return BufferedReader.init(reader);
}

/// Creates a new BufferedWriter wrapping the given writer.
pub fn newWriter(writer: Writer) BufferedWriter {
    return BufferedWriter.init(writer);
}

/// Reads until the first occurrence of delim in the input,
/// returning a slice containing the data up to and including the delimiter.
/// The returned slice is owned by the BufferedReader's internal buffer.
/// If an error is encountered before finding the delimiter, it returns the data read so far.
pub fn readBytes(buf_reader: *BufferedReader, delim: u8) ![]u8 {
    return buf_reader.readUntilDelimiter(delim);
}

/// Reads until the first occurrence of delim in the input,
/// returning a string containing the data up to and including the delimiter.
/// Allocates memory for the string. Caller owns the memory.
pub fn readString(allocator: Allocator, buf_reader: *BufferedReader, delim: u8) ![]u8 {
    // readUntilDelimiterAlloc ensures null termination for safety if needed,
    // but we return the slice without the null terminator.
    const slice_with_null = try buf_reader.readUntilDelimiterAlloc(allocator, delim, std.math.maxInt(usize));
    return slice_with_null[0 .. slice_with_null.len - 1];
}

/// Flushes any buffered data to the underlying writer.
pub fn flush(buf_writer: *BufferedWriter) !void {
    return buf_writer.flush();
}

// --- Tests ---

test "LimitReader" {
    const data = "hello world";
    var stream = io.fixedBufferStream(data);
    var limited_reader_impl = LimitReader(stream.reader(), 5); // Limit to "hello"
    var limited_reader = limited_reader_impl.asReader(); // Get the reader interface

    var buf: [10]u8 = undefined;
    var bytes_read = try limited_reader.read(&buf);
    try testing.expectEqual(@as(usize, 5), bytes_read);
    try testing.expectEqualStrings("hello", buf[0..bytes_read]);

    // Next read should be EOF
    bytes_read = limited_reader.read(&buf) catch |err| {
        // Expect EOF and do nothing else, test passes this point if EOF is caught.
        try testing.expect(err == error.EndOfStream);
        return; // Exit test successfully after catching expected error
    };
    // This part should not be reached if EOF was correctly caught.
    std.debug.print("Unexpectedly read {d} bytes after limit reached.\n", .{bytes_read});
    unreachable;
}

test "TeeReader" {
    const data = "tee test";
    var source_stream = io.fixedBufferStream(data);

    var tee_buf: [20]u8 = undefined;
    var tee_stream = io.fixedBufferStream(&tee_buf);

    var tee_reader_impl = TeeReader(source_stream.reader(), tee_stream.writer());
    var tee_reader = tee_reader_impl.asReader(); // Get the reader interface

    var read_buf: [10]u8 = undefined;
    const bytes_read = try tee_reader.read(&read_buf);

    try testing.expectEqualStrings(data, read_buf[0..bytes_read]);
    try testing.expectEqualStrings(data, tee_stream.getWritten());
}

test "Buffered ReadString/ReadBytes" {
    const allocator = testing.allocator;
    const data = "line1\nline2\nline3";
    var stream = io.fixedBufferStream(data);
    var buf_reader = newReader(stream.reader());

    // ReadBytes
    const line = try readBytes(&buf_reader, '\n'); // Changed var to const
    try testing.expectEqualStrings("line1\n", line);

    // ReadString
    const line_str = try readString(allocator, &buf_reader, '\n'); // Changed var to const
    defer allocator.free(line_str);
    try testing.expectEqualStrings("line2\n", line_str);

    // Read remaining with readAllAlloc (using the underlying reader)
    const remaining = try readAll(allocator, buf_reader.reader(), 100); // Changed var to const
    defer allocator.free(remaining);
    try testing.expectEqualStrings("line3", remaining);
}

test "BufferedWriter flush" {
    var buf: [100]u8 = undefined;
    var stream = io.fixedBufferStream(&buf);
    var buf_writer = newWriter(stream.writer());

    try buf_writer.writer().writeAll("hello");
    // Data might not be in the underlying stream yet
    try testing.expectEqual(@as(usize, 0), stream.getWritten().len);

    try flush(&buf_writer);
    // Now data should be flushed
    try testing.expectEqualStrings("hello", stream.getWritten());
}
