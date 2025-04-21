# zig-myTools Library Documentation

This document provides an overview of the modules and functions available in the `zig-myTools` library.

---

## Modules Overview

### `allocator` (`zallocator`)

Provides custom allocator wrappers.

*   **`CountingAllocator`**: Wraps an allocator to count allocations, frees, bytes allocated/freed, etc.
    *   `init(allocator: Allocator) CountingAllocator`
    *   `asAllocator(self: *CountingAllocator) Allocator`
    *   `resetStats(self: *CountingAllocator) void`
    *   `stats: Stats` (Contains counts and helper methods like `activeAllocations`, `activeBytes`, `reset`, `printStats`)
*   **`LimitedAllocator`**: Wraps an allocator to enforce a memory usage limit.
    *   `init(allocator: Allocator, limit: usize) LimitedAllocator`
    *   `asAllocator(self: *LimitedAllocator) Allocator`
    *   `current_usage: usize`
    *   `limit: usize`

### `asm` (`zasm`)

Provides low-level assembly functions (primarily x86-64). **WARNING: Target-specific and unsafe.**

*   `cpuid(leaf: u32) ?struct { eax: u32, ebx: u32, ecx: u32, edx: u32 }`: Executes the CPUID instruction.
*   `addU64(x: u64, y: u64) ?u64`: Simple addition using inline assembly.
*   `subU64(x: u64, y: u64) ?u64`: Simple subtraction using inline assembly.
*   `atomicAddU64(ptr: *volatile u64, delta: u64) ?void`: Atomic addition using `lock add`.
*   `syscall3(syscall_num: u64, arg1: u64, arg2: u64, arg3: u64) ?u64`: Performs a Linux x86-64 syscall with 3 arguments.

### `async` (`zasync`)

Provides synchronization primitives and atomic operations, similar to Go's `sync` and `sync/atomic`.

*   **Types**:
    *   `Mutex`: Alias for `std.Thread.Mutex`.
    *   `RWMutex`: Alias for `std.Thread.RwLock`.
    *   `Cond`: Alias for `std.Thread.Condition`.
    *   `WaitGroup`: Waits for a collection of threads to complete.
        *   `add(self: *WaitGroup, delta: i64) void`
        *   `done(self: *WaitGroup) void`
        *   `wait(self: *WaitGroup) void`
    *   `Once`: Performs an action exactly once.
        *   `do(self: *Once, f: fn () void) void`
*   **Atomics** (operate on `std.atomic.Atomic(T)`):
    *   `CompareAndSwapBool(addr: *Atomic(bool), old: bool, new: bool) bool`
    *   `LoadBool(addr: *const Atomic(bool)) bool`
    *   `StoreBool(addr: *Atomic(bool), val: bool) void`
    *   `SwapBool(addr: *Atomic(bool), new: bool) bool`
    *   `AddI64(addr: *Atomic(i64), delta: i64) i64` (Returns new value)
    *   `CompareAndSwapI64(addr: *Atomic(i64), old: i64, new: i64) bool`
    *   `LoadI64(addr: *const Atomic(i64)) i64`
    *   `StoreI64(addr: *Atomic(i64), val: i64) void`
    *   `SwapI64(addr: *Atomic(i64), new: i64) i64`
    *   `AddU64(addr: *Atomic(u64), delta: u64) u64` (Returns new value)
    *   `CompareAndSwapU64(addr: *Atomic(u64), old: u64, new: u64) bool`
    *   `LoadU64(addr: *const Atomic(u64)) u64`
    *   `StoreU64(addr: *Atomic(u64), val: u64) void`
    *   `SwapU64(addr: *Atomic(u64), new: u64) u64`
    *   `CompareAndSwapPointer(addr: *Atomic(?*anyopaque), old: ?*anyopaque, new: ?*anyopaque) bool`
    *   `LoadPointer(addr: *const Atomic(?*anyopaque)) ?*anyopaque`
    *   `StorePointer(addr: *Atomic(?*anyopaque), val: ?*anyopaque) void`
    *   `SwapPointer(addr: *Atomic(?*anyopaque), new: ?*anyopaque) ?*anyopaque`

### `bytes` (`zbytes`)

Provides functions for byte slice manipulation.

*   `Compare(a: []const u8, b: []const u8) std.math.Order`: Lexicographical comparison.
*   `Contains(s: []const u8, subslice: []const u8) bool`: Checks if `subslice` is within `s`.
*   `Count(s: []const u8, sep: []const u8) usize`: Counts non-overlapping instances of `sep`.
*   `Fields(allocator: Allocator, s: []const u8) ![][]u8`: Splits `s` by whitespace into allocated fields.
*   `Join(allocator: Allocator, s: [][]const u8, sep: []const u8) ![]u8`: Concatenates elements with a separator.

### `cmp` (`zcmp`)

Provides basic comparison functions.

*   `Compare(comptime T: type, x: T, y: T) std.math.Order`: Generic comparison returning `.lt`, `.eq`, `.gt`.
*   `Less(comptime T: type, x: T, y: T) bool`: Generic less-than comparison.

### `http` (`zhttp`)

Provides a basic HTTP client.

*   **`Client`**: Represents an HTTP client.
    *   `init(allocator: Allocator) Client`
    *   `Get(self: Client, url_str: []const u8) !Response`: Performs a GET request.
*   **`Response`**: Represents a simplified HTTP response.
    *   `status_code: std.http.Status`
    *   `body: []u8`

### `io` (`zio`)

Provides I/O primitives and helpers, similar to Go's `io` and `bufio`.

*   **Interfaces (Aliases)**: `Reader`, `Writer`, `Closer`, `Seeker`
*   **Constants**: `SeekStart`, `SeekCurrent`, `SeekEnd`, `EOF`, `ErrUnexpectedEOF`, `ErrShortWrite`
*   **Functions**:
    *   `copy(writer: Writer, reader: Reader) !u64`
    *   `copyBuffer(writer: Writer, reader: Reader, buf: []u8) !u64`
    *   `readAll(allocator: Allocator, reader: Reader, max_size: usize) ![]u8`
    *   `writeString(writer: Writer, str: []const u8) !void`
    *   `LimitReader(reader: Reader, n: u64) LimitReaderImpl`: Returns a reader limited to `n` bytes.
    *   `TeeReader(reader: Reader, writer: Writer) TeeReaderImpl`: Returns a reader that writes to `writer`.
    *   `multiWriter(writers: []const Writer) std.io.MultiWriter`: Creates a writer that duplicates writes.
    *   `newReader(reader: Reader) BufferedReader`: Creates a buffered reader.
    *   `newWriter(writer: Writer) BufferedWriter`: Creates a buffered writer.
    *   `readBytes(buf_reader: *BufferedReader, delim: u8) ![]u8`: Reads until delimiter (slice owned by buffer).
    *   `readString(allocator: Allocator, buf_reader: *BufferedReader, delim: u8) ![]u8`: Reads until delimiter (allocates string).
    *   `flush(buf_writer: *BufferedWriter) !void`: Flushes buffered writer.
*   **Types**: `LimitReaderImpl`, `TeeReaderImpl`, `BufferedReader`, `BufferedWriter`

### `iter` (`ziter`)

Provides basic iterator helpers.

*   **`RangeIterator`**: Iterator yielding `0..end`.
    *   `next(self: *RangeIterator) ?usize`
*   `Seq(n: usize) RangeIterator`: Creates a `RangeIterator` for `0..n`.

### `math` (`zmath`)

Provides mathematical constants and functions.

*   **Constants**: `E`, `Pi`, `Phi`, `Sqrt2`, `SqrtE`, `SqrtPi`, `SqrtPhi`, `Ln2`, `Log2E`, `Ln10`, `Log10E`, `MaxFloat32`, `SmallestNonzeroFloat32`, `MaxFloat64`, `SmallestNonzeroFloat64`, `MaxInt64`, `MinInt64`, `MaxUint64`.
*   **Functions**:
    *   `Abs(x: anytype) @TypeOf(x)`
    *   `Ceil(x: anytype) @TypeOf(x)` (float only)
    *   `Floor(x: anytype) @TypeOf(x)` (float only)
    *   `Round(x: anytype) @TypeOf(x)` (float only, rounds half away from zero)
    *   `RoundToEven(x: anytype) @TypeOf(x)` (float only, rounds half to even)
    *   `Trunc(x: anytype) @TypeOf(x)` (float only)
    *   `Max(x: anytype, y: @TypeOf(x)) @TypeOf(x)`
    *   `Min(x: anytype, y: @TypeOf(x)) @TypeOf(x)`
    *   `Sqrt(x: anytype) @TypeOf(x)` (float only)
    *   `Pow(x: anytype, y: @TypeOf(x)) @TypeOf(x)` (float only)
    *   `Pow10(n_any: anytype) @TypeOf(n_any)` (int or float)
    *   `Sin(x: anytype) @TypeOf(x)` (float only)
    *   `Cos(x: anytype) @TypeOf(x)` (float only)
    *   `Tan(x: anytype) @TypeOf(x)` (float only)
    *   `Exp(x: anytype) @TypeOf(x)` (float only)
    *   `Log(x: anytype) @TypeOf(x)` (float only, natural log)
    *   `Log10(x: anytype) @TypeOf(x)` (float only, base 10 log)
    *   `Log2(x: anytype) @TypeOf(x)` (float only, base 2 log)
    *   `NaN(comptime T: type) T` (float only)
    *   `Inf(comptime T: type, sign: i8) T` (float only)
    *   `IsInf(f: anytype, sign: i8) bool`
    *   `IsNaN(f: anytype) bool`

### `mem` (`zmem`)

Provides memory-related functions, focusing on slice comparisons.

*   `equalFold(a: []const u8, b: []const u8) bool`: Case-insensitive ASCII equality check.
*   `lastIndex(comptime T: type, haystack: []const T, needle: []const T) ?usize`: Finds last occurrence of `needle`.

### `net` (`znet`)

Provides basic networking types and functions.

*   **Types**:
    *   `IPAddress`: Alias for `std.net.Address`.
    *   `IPParseError`: Alias for `std.net.Address.ParseError`.
*   **Functions**:
    *   `parseIP(s: []const u8) IPParseError!IPAddress`: Parses IPv4 or IPv6 string.

### `reflect` (`zreflect`)

Provides basic reflection capabilities using compile-time introspection.

*   **Types**:
    *   `Type`: Alias for `type`.
    *   `Kind`: Alias for `std.builtin.TypeInfo.Tag`.
    *   `StructField`: Alias for `std.builtin.TypeInfo.StructField`.
*   **Functions**:
    *   `TypeOf(value: anytype) Type`: Returns the compile-time type of `value`.
    *   `TypeKind(comptime T: Type) Kind`: Returns the kind of type `T`.
    *   `NumField(comptime T: Type) usize`: Returns the number of fields in a struct `T`.
    *   `Field(comptime T: Type, i: usize) StructField`: Returns the i-th field info of struct `T`.
    *   `GetField(struct_val: anytype, comptime field_name: []const u8) @TypeOf(@field(struct_val, field_name))`: Gets field value by name.
    *   `SetField(struct_ptr: anytype, comptime field_name: []const u8, value: anytype) void`: Sets field value by name (requires pointer).

### `slices` (`zslices`)

Provides functions for working with slices of any type.

*   `Contains(comptime T: type, s: []const T, v: T) bool`: Checks if `v` is in `s`.
*   `Index(comptime T: type, s: []const T, v: T) ?usize`: Returns index of first `v` in `s`.
*   `IndexScalar(comptime T: type, s: []const T, v: T) ?usize`: Optimized `Index` for scalar types.
*   `Sort(comptime T: type, s: []T, ctx: anytype) void`: Sorts slice `s` using context `ctx`.
*   `Reverse(comptime T: type, s: []T) void`: Reverses slice `s` in place.
*   `Clone(comptime T: type, allocator: Allocator, s: []const T) ![]T`: Creates an allocated copy of `s`.

### `sort` (`zsort`)

Provides sorting-related utility functions.

*   `isSorted(comptime T: type, s: []const T, ctx: anytype) bool`: Checks if slice `s` is sorted using context `ctx`.
*   `Search(comptime T: type, s: []const T, x: T, ctx: anytype) usize`: Finds index `i` where `s[i] >= x` (lower bound).

### `strings` (`zstrings`)

Provides functions for string manipulation (UTF-8 byte slices).

*   `reverse(allocator: Allocator, s: []const u8) ![]u8`: Returns an allocated reversed copy.
*   `trim(s: []const u8, cutset: []const u8) []const u8`: Removes leading/trailing chars from `cutset`.
*   `startsWith(s: []const u8, prefix: []const u8) bool`: Checks for prefix.
*   `endsWith(s: []const u8, suffix: []const u8) bool`: Checks for suffix.
*   `toUpperCase(allocator: Allocator, s: []const u8) ![]u8`: Returns allocated uppercase copy (ASCII).
*   `toLowerCase(allocator: Allocator, s: []const u8) ![]u8`: Returns allocated lowercase copy (ASCII).
*   `isPalindrome(s: []const u8) bool`: Checks if string is a palindrome (byte-wise).

### `time` (`ztime`)

Provides time-related types and functions.

*   **Types**:
    *   `Duration`: Represents a time duration (nanoseconds).
    *   `Time`: Represents a specific point in time.
*   **Constants**: `Nanosecond`, `Microsecond`, `Millisecond`, `Second`, `Minute`, `Hour` (all `Duration` values). `LayoutIso`, `LayoutRfc3339`, `LayoutDateOnly`, `LayoutTimeOnly` (format strings).
*   **Functions**:
    *   `Now() Time`: Returns the current time.
    *   `Time.FromUnix(sec: i64, nsec: i64) Time`: Creates Time from Unix seconds/nanoseconds.
    *   `Time.FromUnixNano(nsec: i64) Time`: Creates Time from Unix nanoseconds.
    *   `Sleep(duration: Duration) void`: Pauses the current thread.
    *   `Parse(layout: []const u8, value: []const u8) !Time`: Parses a time string using a layout.
    *   (Methods on `Time`): `unix() i64`, `unixNano() i64`, `add(d: Duration) Time`, `sub(t2: Time) Duration`, `format(allocator: Allocator, layout: []const u8) ![]u8`, etc.
    *   (Methods on `Duration`): `nanoseconds() i64`, `seconds() f64`, `minutes() f64`, `hours() f64`, etc.

### `ws` (`zws`)

Provides basic WebSocket connection handling (server-side upgrade).

*   **Constants**: `OpcodeText`, `OpcodeBinary`, `OpcodeClose`, `OpcodePing`, `OpcodePong`. `MessageTypeText`, `MessageTypeBinary`, etc.
*   **Types**:
    *   `Conn`: Represents a WebSocket connection (placeholder implementation).
        *   `init(conn: net.StreamConn, allocator: Allocator, is_server: bool, read_buf_size: usize, write_buf_size: usize) !Conn`
        *   `deinit(self: *Conn) void`
        *   `ReadMessage(self: *Conn) !struct { message_type: u8, data: []u8 }` (placeholder)
        *   `WriteMessage(self: *Conn, message_type: u8, data: []const u8) !void` (placeholder)
    *   `Upgrader`: Handles HTTP to WebSocket upgrade.
        *   `Upgrade(self: Upgrader, resp: *http.Server.Response, req: *const http.Server.Request, underlying_conn: ?net.StreamConn) !Conn`

### `zmt`

Provides simple printing functions similar to Go's `fmt` package (writing to stdout).

*   `Print(args: anytype) !usize`: Prints arguments with default formatting.
*   `Println(args: anytype) !usize`: Prints arguments with spaces and a newline.
*   `Printf(comptime format: []const u8, args: anytype) !usize`: Prints formatted output.
*   `Sprintf(allocator: Allocator, comptime format: []const u8, args: anytype) ![]u8`: Formats to an allocated string.
*   `Fprintf(writer: anytype, comptime format: []const u8, args: anytype) !usize`: Formats to a writer.

---

## How to Use This Library

To use `zig-myTools` in your own Zig project:

1.  **Add as a Dependency:**
    You need to tell your `build.zig` file where to find the `zig-myTools` library and how to incorporate it. The most common way is using Zig's package manager features.

    *   **Using `build.zig.zon` (Recommended for Zig >= 0.11):**
        a.  Create or update the `build.zig.zon` file in your project's root directory.
        b.  Add `zig-myTools` to the `.dependencies` map. You'll typically specify a URL and a hash:

            ```zon
            .{
                .name = "your_project_name",
                .version = "0.1.0",
                .dependencies = .{
                    // Add zig-myTools dependency
                    .zig_myTools = .{
                        .url = "https://github.com/brandonstewart/zig-myTools/archive/<commit_hash_or_tag>.tar.gz", // Replace with actual commit hash or tag
                        .hash = "1220...", // Replace with the actual content hash (zig build fetches this)
                    },
                },
                .paths = .{""}, // Add other paths if needed
            }
            ```
            Run `zig build` once. Zig will download the dependency and tell you the correct `.hash` to put in the `.zon` file if you initially put a placeholder.

        c.  In your `build.zig`, get the dependency and add it as a module:

            ```zig
            const std = @import("std");

            pub fn build(b: *std.Build) void {
                const target = b.standardTargetOptions(.{});
                const optimize = b.standardOptimizeOption(.{});

                // Get the dependency object
                const mytools_dep = b.dependency("zig_myTools", .{
                    .target = target,
                    .optimize = optimize,
                });

                // Get the module from the dependency
                const mytools_module = mytools_dep.module("zig_myTools"); // "zig_myTools" is the name defined in its build.zig

                const exe = b.addExecutable(.{
                    .name = "your_project_name",
                    .root_source_file = b.path("src/main.zig"),
                    .target = target,
                    .optimize = optimize,
                });

                // Add the module as an import for your executable/library
                exe.addModule("zmt", mytools_module); // "zmt" is the import name you'll use in code

                b.installArtifact(exe);
                // ... other build steps ...
            }
            ```

    *   **Manual Download / Git Submodule:**
        a.  Place the `zig-myTools` source code somewhere accessible to your project (e.g., in a `libs/` directory, or as a git submodule).
        b.  In your `build.zig`, create a module pointing to the `zig-myTools` `src/root.zig` file:

            ```zig
            const std = @import("std");

            pub fn build(b: *std.Build) void {
                const target = b.standardTargetOptions(.{});
                const optimize = b.standardOptimizeOption(.{});

                // Create a module for the zig-myTools library
                const mytools_module = b.createModule(.{
                    .root_source_file = b.path("path/to/zig-myTools/src/root.zig"), // Adjust path
                    // Add source files if root.zig doesn't import them all (though it should)
                });

                const exe = b.addExecutable(.{
                    .name = "your_project_name",
                    .root_source_file = b.path("src/main.zig"),
                    .target = target,
                    .optimize = optimize,
                });

                // Add the module as an import
                exe.addModule("zmt", mytools_module); // "zmt" is the import name

                b.installArtifact(exe);
                // ... other build steps ...
            }
            ```

2.  **Import in Your Zig Code:**
    Once configured in `build.zig`, you can import the library using the name you specified in `addModule` (e.g., `"zmt"` in the examples above).

    ```zig
    const std = @import("std");
    const zmt = @import("zmt"); // Use the import name from build.zig

    pub fn main() !void {
        // Use functions directly re-exported from root.zig
        const reversed = try zmt.reverse(std.testing.allocator, "hello");
        defer std.testing.allocator.free(reversed);
        _ = try zmt.Printf("Reversed: {s}\n", .{reversed});

        // Access functions from specific submodules via the root import
        const ip = try zmt.znet.parseIP("127.0.0.1");
        _ = try zmt.Printf("IP: {any}\n", .{ip});

        // Use a type
        var wg = zmt.WaitGroup{};
        wg.add(1);
        // ... spawn thread ...
        wg.done();
        wg.wait();

        _ = try zmt.Println("Done!");
    }
    ```

// <3