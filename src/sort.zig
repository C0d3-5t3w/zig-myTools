const std = @import("std");
const sort = std.sort;
const testing = std.testing;

/// Reports whether the slice `s` is sorted in ascending order.
/// Requires a comparison context `ctx` with a `lessThan` function.
pub fn isSorted(comptime T: type, s: []const T, ctx: anytype) bool {
    if (s.len < 2) {
        return true;
    }
    var i: usize = 1;
    while (i < s.len) : (i += 1) {
        // If s[i] < s[i-1], it's not sorted
        if (ctx.lessThan(s[i], s[i - 1])) {
            return false;
        }
    }
    return true;
}

// Convenience struct for standard lessThan comparison
const StandardContext = struct {
    pub fn lessThan(_: @This(), a: anytype, b: anytype) bool {
        return a < b;
    }
};

test "isSorted" {
    const sorted_i32 = &[_]i32{ 1, 2, 3, 4, 5 };
    const unsorted_i32 = &[_]i32{ 1, 3, 2, 4, 5 };
    const reversed_i32 = &[_]i32{ 5, 4, 3, 2, 1 };
    const single_i32 = &[_]i32{10};
    const empty_i32 = &[_]i32{};
    const equal_i32 = &[_]i32{ 2, 2, 2 };

    try testing.expect(isSorted(i32, sorted_i32, StandardContext{}));
    try testing.expect(!isSorted(i32, unsorted_i32, StandardContext{}));
    try testing.expect(!isSorted(i32, reversed_i32, StandardContext{}));
    try testing.expect(isSorted(i32, single_i32, StandardContext{}));
    try testing.expect(isSorted(i32, empty_i32, StandardContext{}));
    try testing.expect(isSorted(i32, equal_i32, StandardContext{}));

    const sorted_str = &[_][]const u8{ "apple", "banana", "cherry" };
    const unsorted_str = &[_][]const u8{ "cherry", "apple", "banana" };
    // Need a context for string comparison
    const StringContext = struct {
        pub fn lessThan(_: @This(), a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    };
    try testing.expect(isSorted([]const u8, sorted_str, StringContext{}));
    try testing.expect(!isSorted([]const u8, unsorted_str, StringContext{}));
}

/// Searches for `x` in a sorted slice `s` and returns the index `i` in `[0, s.len]`
/// such that `s[i] >= x`. If `x` is greater than all elements in `s`, it returns `s.len`.
/// Requires a comparison context `ctx` with a `lessThan` function.
/// This is similar to Go's sort.Search or C++'s std::lower_bound.
pub fn Search(comptime T: type, s: []const T, x: T, ctx: anytype) usize {
    // Use std.sort.binarySearch to find the insertion point.
    // binarySearch finds an *exact* match. We need the lower bound.
    var low: usize = 0;
    var high: usize = s.len;
    while (low < high) {
        const mid = low + (high - low) / 2;
        // if s[mid] < x, search in the right half (mid+1 .. high)
        if (ctx.lessThan(s[mid], x)) {
            low = mid + 1;
        } else {
            // otherwise, search in the left half (low .. mid)
            high = mid;
        }
    }
    return low; // low is the insertion point
}

test "Search" {
    const sorted_i32 = &[_]i32{ 10, 20, 30, 40, 50 };

    // Existing elements
    try testing.expectEqual(@as(usize, 0), Search(i32, sorted_i32, 10, StandardContext{}));
    try testing.expectEqual(@as(usize, 2), Search(i32, sorted_i32, 30, StandardContext{}));
    try testing.expectEqual(@as(usize, 4), Search(i32, sorted_i32, 50, StandardContext{}));

    // Non-existing elements (insertion points)
    try testing.expectEqual(@as(usize, 0), Search(i32, sorted_i32, 5, StandardContext{})); // Before start
    try testing.expectEqual(@as(usize, 1), Search(i32, sorted_i32, 15, StandardContext{})); // Between 10 and 20
    try testing.expectEqual(@as(usize, 3), Search(i32, sorted_i32, 35, StandardContext{})); // Between 30 and 40
    try testing.expectEqual(@as(usize, 5), Search(i32, sorted_i32, 55, StandardContext{})); // After end

    // Duplicates
    const sorted_dup_i32 = &[_]i32{ 10, 20, 20, 20, 30 };
    try testing.expectEqual(@as(usize, 1), Search(i32, sorted_dup_i32, 20, StandardContext{})); // Finds first '20'

    // Empty slice
    const empty_i32 = &[_]i32{};
    try testing.expectEqual(@as(usize, 0), Search(i32, empty_i32, 100, StandardContext{}));
}
