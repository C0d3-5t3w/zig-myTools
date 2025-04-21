const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const testing = std.testing;
const fmt = std.fmt;
const io = std.io;

/// A wrapper around an allocator that counts allocations, reallocations, frees,
/// and the total number of bytes allocated and freed.
pub const CountingAllocator = struct {
    allocator: Allocator, // The underlying allocator
    stats: Stats = .{}, // Allocation statistics

    // Statistics structure
    pub const Stats = struct {
        alloc_count: u64 = 0,
        realloc_count: u64 = 0,
        free_count: u64 = 0,
        bytes_allocated: u64 = 0,
        bytes_freed: u64 = 0,

        /// Returns the current number of active allocations (allocs - frees).
        pub fn activeAllocations(self: Stats) i64 {
            return @as(i64, @intCast(self.alloc_count)) - @as(i64, @intCast(self.free_count));
        }

        /// Returns the current number of bytes outstanding (allocated - freed).
        pub fn activeBytes(self: Stats) i64 {
            return @as(i64, @intCast(self.bytes_allocated)) - @as(i64, @intCast(self.bytes_freed));
        }

        /// Resets all statistics counters to zero.
        pub fn reset(self: *Stats) void {
            self.alloc_count = 0;
            self.realloc_count = 0;
            self.free_count = 0;
            self.bytes_allocated = 0;
            self.bytes_freed = 0;
        }

        /// Prints the statistics to the given writer.
        pub fn printStats(self: Stats, writer: anytype) !void {
            try writer.print("Allocation Stats:\n", .{});
            try writer.print("  Alloc Count:      {d}\n", .{self.alloc_count});
            try writer.print("  Realloc Count:    {d}\n", .{self.realloc_count});
            try writer.print("  Free Count:       {d}\n", .{self.free_count});
            try writer.print("  Bytes Allocated:  {d}\n", .{self.bytes_allocated});
            try writer.print("  Bytes Freed:      {d}\n", .{self.bytes_freed});
            try writer.print("  Active Allocs:    {d}\n", .{self.activeAllocations()});
            try writer.print("  Active Bytes:     {d}\n", .{self.activeBytes()});
        }
    };

    pub fn init(allocator: Allocator) CountingAllocator {
        return .{ .allocator = allocator };
    }

    /// Returns the Allocator interface for this CountingAllocator.
    pub fn comptimeVTable(_: *CountingAllocator) *const Allocator.VTable {
        return &.{
            .alloc = alloc,
            .resize = resize,
            .free = free,
        };
    }

    /// Returns the Allocator interface for this CountingAllocator.
    pub fn asAllocator(self: *CountingAllocator) Allocator {
        return .{
            .ptr = self,
            .vtable = comptimeVTable(self),
        };
    }

    /// Resets the allocation statistics.
    pub fn resetStats(self: *CountingAllocator) void {
        self.stats.reset();
    }

    fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
        const self: *CountingAllocator = @ptrCast(@alignCast(ctx));
        const ptr = self.allocator.rawAlloc(len, ptr_align, ret_addr);
        if (ptr != null) {
            self.stats.alloc_count += 1;
            self.stats.bytes_allocated += len;
        }
        return ptr;
    }

    fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) ?usize {
        const self: *CountingAllocator = @ptrCast(@alignCast(ctx));
        const old_len = buf.len;
        const success = self.allocator.rawResize(buf, buf_align, new_len, ret_addr);
        if (success) {
            self.stats.realloc_count += 1;
            if (new_len > old_len) {
                self.stats.bytes_allocated += (new_len - old_len);
            } else {
                self.stats.bytes_freed += (old_len - new_len);
            }
            return new_len; // Return the new size on success
        } else {
            // If resize fails but new_len is 0, it's like a free
            if (new_len == 0) {
                self.stats.free_count += 1;
                self.stats.bytes_freed += old_len;
            }
            return null; // Indicate failure
        }
    }

    fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
        const self: *CountingAllocator = @ptrCast(@alignCast(ctx));
        self.allocator.rawFree(buf, buf_align, ret_addr);
        self.stats.free_count += 1;
        self.stats.bytes_freed += buf.len;
    }
};

/// A wrapper around an allocator that limits the total amount of active memory.
pub const LimitedAllocator = struct {
    allocator: Allocator, // The underlying allocator
    limit: usize, // Maximum number of active bytes allowed
    current_usage: usize = 0, // Current number of active bytes

    pub const Error = error{OutOfMemory};

    pub fn init(allocator: Allocator, limit: usize) LimitedAllocator {
        return .{ .allocator = allocator, .limit = limit };
    }

    /// Returns the Allocator interface for this LimitedAllocator.
    pub fn comptimeVTable(_: *LimitedAllocator) *const Allocator.VTable {
        return &.{
            .alloc = alloc,
            .resize = resize,
            .free = free,
        };
    }

    /// Returns the Allocator interface for this LimitedAllocator.
    pub fn asAllocator(self: *LimitedAllocator) Allocator {
        return .{
            .ptr = self,
            .vtable = comptimeVTable(self),
        };
    }

    fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
        const self: *LimitedAllocator = @ptrCast(@alignCast(ctx));
        if (self.current_usage + len > self.limit) {
            return null; // Exceeds limit
        }
        const ptr = self.allocator.rawAlloc(len, ptr_align, ret_addr);
        if (ptr != null) {
            self.current_usage += len;
        }
        return ptr;
    }

    fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) ?usize {
        const self: *LimitedAllocator = @ptrCast(@alignCast(ctx));
        const old_len = buf.len;
        const diff: isize = @as(isize, @intCast(new_len)) - @as(isize, @intCast(old_len));

        if (diff > 0 and self.current_usage + @as(usize, @intCast(diff)) > self.limit) {
            return null; // Growing would exceed limit
        }

        const success = self.allocator.rawResize(buf, buf_align, new_len, ret_addr);
        if (success) {
            self.current_usage = @as(usize, @intCast(@as(isize, @intCast(self.current_usage)) + diff));
            return new_len;
        } else {
            // If resize fails but new_len is 0, it's like a free
            if (new_len == 0) {
                self.current_usage -= old_len;
            }
            return null;
        }
    }

    fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
        const self: *LimitedAllocator = @ptrCast(@alignCast(ctx));
        self.allocator.rawFree(buf, buf_align, ret_addr);
        self.current_usage -= buf.len;
    }
};

test "CountingAllocator" {
    const test_allocator = testing.allocator;
    var counting_alloc = CountingAllocator.init(test_allocator);
    const allocator = counting_alloc.asAllocator(); // Use renamed method

    // Test alloc
    const ptr1 = try allocator.alloc(u8, 10);
    try testing.expectEqual(@as(u64, 1), counting_alloc.stats.alloc_count);
    try testing.expectEqual(@as(u64, 10), counting_alloc.stats.bytes_allocated);
    try testing.expectEqual(@as(i64, 1), counting_alloc.stats.activeAllocations());
    try testing.expectEqual(@as(i64, 10), counting_alloc.stats.activeBytes());

    // Test resize (grow)
    const ptr2 = try allocator.realloc(ptr1, 20);
    try testing.expectEqual(@as(u64, 1), counting_alloc.stats.alloc_count); // alloc count unchanged
    try testing.expectEqual(@as(u64, 1), counting_alloc.stats.realloc_count);
    try testing.expectEqual(@as(u64, 20), counting_alloc.stats.bytes_allocated); // 10 initial + 10 added
    try testing.expectEqual(@as(u64, 0), counting_alloc.stats.bytes_freed);
    try testing.expectEqual(@as(i64, 1), counting_alloc.stats.activeAllocations());
    try testing.expectEqual(@as(i64, 20), counting_alloc.stats.activeBytes());

    // Test resize (shrink)
    const ptr3 = try allocator.realloc(ptr2, 5);
    try testing.expectEqual(@as(u64, 1), counting_alloc.stats.alloc_count);
    try testing.expectEqual(@as(u64, 2), counting_alloc.stats.realloc_count);
    try testing.expectEqual(@as(u64, 20), counting_alloc.stats.bytes_allocated);
    try testing.expectEqual(@as(u64, 15), counting_alloc.stats.bytes_freed); // 20 - 5 = 15 freed
    try testing.expectEqual(@as(i64, 1), counting_alloc.stats.activeAllocations());
    try testing.expectEqual(@as(i64, 5), counting_alloc.stats.activeBytes());

    // Test free
    allocator.free(ptr3);
    try testing.expectEqual(@as(u64, 1), counting_alloc.stats.alloc_count);
    try testing.expectEqual(@as(u64, 2), counting_alloc.stats.realloc_count);
    try testing.expectEqual(@as(u64, 1), counting_alloc.stats.free_count);
    try testing.expectEqual(@as(u64, 20), counting_alloc.stats.bytes_allocated);
    try testing.expectEqual(@as(u64, 20), counting_alloc.stats.bytes_freed); // 15 from shrink + 5 from free
    try testing.expectEqual(@as(i64, 0), counting_alloc.stats.activeAllocations());
    try testing.expectEqual(@as(i64, 0), counting_alloc.stats.activeBytes());

    // Test another alloc/free cycle
    const ptr4 = try allocator.alloc(u8, 8);
    allocator.free(ptr4);
    try testing.expectEqual(@as(u64, 2), counting_alloc.stats.alloc_count);
    try testing.expectEqual(@as(u64, 2), counting_alloc.stats.free_count);
    try testing.expectEqual(@as(u64, 28), counting_alloc.stats.bytes_allocated); // 20 + 8
    try testing.expectEqual(@as(u64, 28), counting_alloc.stats.bytes_freed); // 20 + 8
    try testing.expectEqual(@as(i64, 0), counting_alloc.stats.activeAllocations());
    try testing.expectEqual(@as(i64, 0), counting_alloc.stats.activeBytes());

    // Test resetStats
    counting_alloc.resetStats();
    try testing.expectEqual(@as(u64, 0), counting_alloc.stats.alloc_count);
    try testing.expectEqual(@as(u64, 0), counting_alloc.stats.realloc_count);
    try testing.expectEqual(@as(u64, 0), counting_alloc.stats.free_count);
    try testing.expectEqual(@as(u64, 0), counting_alloc.stats.bytes_allocated);
    try testing.expectEqual(@as(u64, 0), counting_alloc.stats.bytes_freed);
    try testing.expectEqual(@as(i64, 0), counting_alloc.stats.activeAllocations());
    try testing.expectEqual(@as(i64, 0), counting_alloc.stats.activeBytes());

    // Test after reset
    const ptr5 = try allocator.alloc(u8, 100);
    try testing.expectEqual(@as(u64, 1), counting_alloc.stats.alloc_count);
    try testing.expectEqual(@as(u64, 100), counting_alloc.stats.bytes_allocated);
    allocator.free(ptr5);
    try testing.expectEqual(@as(u64, 1), counting_alloc.stats.free_count);
    try testing.expectEqual(@as(u64, 100), counting_alloc.stats.bytes_freed);
    try testing.expectEqual(@as(i64, 0), counting_alloc.stats.activeBytes());

    // Test printStats
    var buf: [256]u8 = undefined;
    var fixed_buffer_stream = io.fixedBufferStream(&buf);
    const writer = fixed_buffer_stream.writer();
    try counting_alloc.stats.printStats(writer);
    const output = fixed_buffer_stream.getWritten();
    // Basic check for output format
    try testing.expect(std.mem.containsAtLeast(u8, output, 1, "Alloc Count:"));
    try testing.expect(std.mem.containsAtLeast(u8, output, 1, "Active Bytes:     0"));
}

test "LimitedAllocator" {
    const test_allocator = testing.allocator;
    var limited_alloc = LimitedAllocator.init(test_allocator, 100); // Limit of 100 bytes
    const allocator = limited_alloc.asAllocator();

    // Alloc within limit
    const ptr1 = try allocator.alloc(u8, 50);
    try testing.expectEqual(@as(usize, 50), limited_alloc.current_usage);

    // Alloc exactly at limit
    const ptr2 = try allocator.alloc(u8, 50);
    try testing.expectEqual(@as(usize, 100), limited_alloc.current_usage);

    // Alloc exceeding limit
    const ptr3 = allocator.rawAlloc(1, 1, @returnAddress());
    try testing.expect(ptr3 == null);
    try testing.expectEqual(@as(usize, 100), limited_alloc.current_usage); // Usage unchanged

    // Free some memory
    allocator.free(ptr1);
    try testing.expectEqual(@as(usize, 50), limited_alloc.current_usage);

    // Alloc again within new limit
    const ptr4 = try allocator.alloc(u8, 30);
    try testing.expectEqual(@as(usize, 80), limited_alloc.current_usage);

    // Resize grow within limit
    const ptr5 = try allocator.realloc(ptr4, 40); // Grow from 30 to 40 (+10 bytes)
    try testing.expectEqual(@as(usize, 90), limited_alloc.current_usage); // 50 (ptr2) + 40 (ptr5)

    // Resize grow exceeding limit
    const resize_fail = allocator.rawResize(ptr5, 1, 61, @returnAddress()); // Grow from 40 to 61 (+21 bytes), total 50+61=111 > 100
    try testing.expect(!resize_fail);
    try testing.expectEqual(@as(usize, 90), limited_alloc.current_usage); // Usage unchanged

    // Resize shrink
    const ptr6 = try allocator.realloc(ptr5, 10); // Shrink from 40 to 10 (-30 bytes)
    try testing.expectEqual(@as(usize, 60), limited_alloc.current_usage); // 50 (ptr2) + 10 (ptr6)

    // Free remaining
    allocator.free(ptr2);
    allocator.free(ptr6);
    try testing.expectEqual(@as(usize, 0), limited_alloc.current_usage);

    // Test resize to 0 (acts like free)
    const ptr7 = try allocator.alloc(u8, 20);
    try testing.expectEqual(@as(usize, 20), limited_alloc.current_usage);
    const resize_to_zero = try allocator.realloc(ptr7, 0);
    try testing.expectEqual(@as(usize, 0), limited_alloc.current_usage);
    // Note: ptr7 is now invalid, but the memory is freed via resize(0)
    _ = resize_to_zero; // Suppress unused variable warning
}
