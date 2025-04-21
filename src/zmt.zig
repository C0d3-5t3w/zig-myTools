const std = @import("std");
const io = std.io;
const fmt = std.fmt;

const stdout_writer = io.getStdOut().writer();

/// Formats using the default formats for its operands and writes to standard output.
/// Spaces are added between operands when neither is a string.
/// Returns the number of bytes written and any write error.
/// Note: This is a simplified version. Handling multiple arbitrary types
/// requires careful consideration of formatting rules. This version uses default formatting.
pub fn Print(args: anytype) !usize {
    return fmt.print("{}", .{args});
}

/// Formats using the default formats for its operands and writes to standard output.
/// Spaces are always added between operands and a newline is appended.
/// Returns the number of bytes written and any write error.
/// Note: Simplified version for a single argument. A full implementation
/// would handle multiple arguments with spacing.
pub fn Println(args: anytype) !usize {
    // A more complete version would iterate through multiple args, adding spaces.
    return fmt.print("{}\n", .{args});
}

/// Formats according to a format specifier and writes to standard output.
/// Returns the number of bytes written and any write error.
/// It is equivalent to fmt.Fprintf(os.Stdout, format, a...).
pub fn Printf(comptime format: []const u8, args: anytype) !usize {
    return fmt.print(format, args);
}

// --- Sprintf style functions ---

/// Formats according to a format specifier and returns the resulting string.
pub fn Sprintf(allocator: std.mem.Allocator, comptime format: []const u8, args: anytype) ![]u8 {
    return fmt.allocPrint(allocator, format, args);
}

// --- Fprintf style functions ---

/// Formats according to a format specifier and writes to w.
/// Returns the number of bytes written and any write error.
pub fn Fprintf(writer: anytype, comptime format: []const u8, args: anytype) !usize {
    return fmt.format(writer, format, args);
}

test "zmt Print, Println, Printf" {
    // Testing stdout printing is tricky in automated tests.
    // We will primarily test the formatting functions like Sprintf.
    const allocator = std.testing.allocator;

    // Test Sprintf
    var str = try Sprintf(allocator, "Hello, {s}!", .{"World"});
    defer allocator.free(str);
    try std.testing.expectEqualStrings("Hello, World!", str);

    str = try Sprintf(allocator, "Value: {d}", .{123});
    defer allocator.free(str);
    try std.testing.expectEqualStrings("Value: 123", str);

    str = try Sprintf(allocator, "{d} {s} {b}", .{ 42, "is", true });
    defer allocator.free(str);
    try std.testing.expectEqualStrings("42 is true", str);

    // Test Fprintf (using a buffer as the writer)
    var buf: [100]u8 = undefined;
    var fixed_buffer_stream = io.fixedBufferStream(&buf);
    const writer = fixed_buffer_stream.writer();

    _ = try Fprintf(writer, "Test: {d}", .{99});
    const written_slice = fixed_buffer_stream.getWritten();
    try std.testing.expectEqualStrings("Test: 99", written_slice);

    // Note: Directly testing Print, Println, Printf would require capturing stdout,
    // which is more involved. Sprintf and Fprintf cover the formatting logic.
}
