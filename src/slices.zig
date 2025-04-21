const std = @import("std");
const mem = std.mem;
const sort = std.sort;
const testing = std.testing;
const Allocator = mem.Allocator;

/// Reports whether `v` is present in `s`.
pub fn Contains(comptime T: type, s: []const T, v: T) bool {
    return Index(T, s, v) != null;
}

test "Contains" {
    const slice_i32 = &[_]i32{ 1, 2, 3, 4 };
    try testing.expect(Contains(i32, slice_i32, 3));
    try testing.expect(!Contains(i32, slice_i32, 5));

    const slice_str = &[_][]const u8{ "apple", "banana", "cherry" };
    try testing.expect(Contains([]const u8, slice_str, "banana"));
    try testing.expect(!Contains([]const u8, slice_str, "grape"));

    const empty_slice = &[_]u8{};
    try testing.expect(!Contains(u8, empty_slice, 0));
}

/// Returns the index of the first occurrence of `v` in `s`, or `null` if not present.
pub fn Index(comptime T: type, s: []const T, v: T) ?usize {
    return mem.indexOf(T, s, &.{v});
}

// Overload for scalar types for potential efficiency
pub fn IndexScalar(comptime T: type, s: []const T, v: T) ?usize {
    if (!@typeInfo(T).Pointer.is_scalar) {
        @compileError("IndexScalar requires a scalar type. Use Index instead.");
    }
    return mem.indexOfScalar(T, s, v);
}

test "Index" {
    const slice_i32 = &[_]i32{ 10, 20, 30, 20, 40 };
    try testing.expectEqual(@as(?usize, 1), IndexScalar(i32, slice_i32, 20));
    try testing.expectEqual(@as(?usize, 2), IndexScalar(i32, slice_i32, 30));
    try testing.expectEqual(@as(?usize, null), IndexScalar(i32, slice_i32, 50));

    const slice_str = &[_][]const u8{ "a", "b", "c", "b" };
    try testing.expectEqual(@as(?usize, 1), Index([]const u8, slice_str, "b"));
    try testing.expectEqual(@as(?usize, null), Index([]const u8, slice_str, "d"));

    const empty_slice = &[_]f32{};
    try testing.expectEqual(@as(?usize, null), IndexScalar(f32, empty_slice, 1.0));
}

/// Sorts the slice `s` in ascending order.
/// Requires a comparison context `ctx` with a `lessThan` function.
pub fn Sort(comptime T: type, s: []T, ctx: anytype) void {
    sort.sort(T, s, ctx, comptime ctx.lessThan);
}

// Convenience struct for standard lessThan comparison
const StandardContext = struct {
    pub fn lessThan(_: @This(), a: anytype, b: anytype) bool {
        return a < b;
    }
};

test "Sort" {
    var slice_i32 = [_]i32{ 4, 1, 3, 2 };
    Sort(i32, &slice_i32, StandardContext{});
    try testing.expectEqualSlices(i32, &[_]i32{ 1, 2, 3, 4 }, &slice_i32);

    var slice_f32 = [_]f32{ 3.3, 1.1, 4.4, 2.2 };
    Sort(f32, &slice_f32, StandardContext{});
    try testing.expectEqualSlices(f32, &[_]f32{ 1.1, 2.2, 3.3, 4.4 }, &slice_f32);

    // Note: Sorting strings requires a specific context or using std.sort.sortStrings
    var slice_str = [_][]const u8{ "cherry", "apple", "banana" };
    sort.sortStrings(slice_str[0..]); // Using std lib sort for strings directly
    try testing.expectEqualSlices([]const u8, &[_][]const u8{ "apple", "banana", "cherry" }, &slice_str);
}

/// Reverses the elements of the slice `s` in place.
pub fn Reverse(comptime T: type, s: []T) void {
    var i: usize = 0;
    var j: usize = s.len;
    while (i < j) : (i += 1) {
        j -= 1;
        const tmp = s[i];
        s[i] = s[j];
        s[j] = tmp;
    }
}

test "Reverse" {
    var slice1 = [_]i32{ 1, 2, 3, 4, 5 };
    Reverse(i32, &slice1);
    try testing.expectEqualSlices(i32, &[_]i32{ 5, 4, 3, 2, 1 }, &slice1);

    var slice2 = [_]u8{ 'a', 'b', 'c', 'd' };
    Reverse(u8, &slice2);
    try testing.expectEqualSlices(u8, &[_]u8{ 'd', 'c', 'b', 'a' }, &slice2);

    var slice3 = [_]i32{1};
    Reverse(i32, &slice3);
    try testing.expectEqualSlices(i32, &[_]i32{1}, &slice3);

    var slice4 = [_]i32{};
    Reverse(i32, &slice4);
    try testing.expectEqualSlices(i32, &[_]i32{}, &slice4);
}

/// Allocates a new slice with the same elements as `s`.
/// The caller owns the returned memory.
pub fn Clone(comptime T: type, allocator: Allocator, s: []const T) ![]T {
    return allocator.dupe(T, s);
}

test "Clone" {
    const allocator = testing.allocator;
    const original = &[_]i32{ 10, 20, 30 };
    const cloned = try Clone(i32, allocator, original);
    defer allocator.free(cloned);

    try testing.expectEqualSlices(i32, original, cloned);
    // Ensure it's a distinct copy
    try testing.expect(original.ptr != cloned.ptr);

    const empty_original = &[_]u8{};
    const empty_cloned = try Clone(u8, allocator, empty_original);
    defer allocator.free(empty_cloned);
    try testing.expectEqualSlices(u8, empty_original, empty_cloned);
    try testing.expect(empty_cloned.len == 0);
}
