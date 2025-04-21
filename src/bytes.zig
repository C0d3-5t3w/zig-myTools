const std = @import("std");
const mem = std.mem;
const ascii = std.ascii;
const testing = std.testing;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

/// Compares two byte slices lexicographically.
/// Returns -1 if a < b, 0 if a == b, and 1 if a > b.
pub fn Compare(a: []const u8, b: []const u8) std.math.Order {
    return mem.order(u8, a, b);
}

test "Compare" {
    try testing.expect(Compare("a", "b") == .lt);
    try testing.expect(Compare("b", "a") == .gt);
    try testing.expect(Compare("a", "a") == .eq);
    try testing.expect(Compare("abc", "abd") == .lt);
    try testing.expect(Compare("abc", "ab") == .gt);
    try testing.expect(Compare("ab", "abc") == .lt);
    try testing.expect(Compare("", "") == .eq);
    try testing.expect(Compare("a", "") == .gt);
    try testing.expect(Compare("", "a") == .lt);
}

/// Reports whether `subslice` is within `s`.
pub fn Contains(s: []const u8, subslice: []const u8) bool {
    return mem.contains(u8, s, subslice);
}

test "Contains" {
    try testing.expect(Contains("hello world", "world"));
    try testing.expect(Contains("hello world", "hello"));
    try testing.expect(Contains("hello world", "lo w"));
    try testing.expect(!Contains("hello world", "goodbye"));
    try testing.expect(Contains("abc", "")); // Empty subslice is always contained
    try testing.expect(Contains("", ""));
    try testing.expect(!Contains("", "a"));
}

/// Counts the number of non-overlapping instances of `sep` in `s`.
/// If `sep` is an empty slice, Count returns `s.len + 1`.
pub fn Count(s: []const u8, sep: []const u8) usize {
    if (sep.len == 0) {
        return s.len + 1; // Match Go's behavior
    }
    if (sep.len > s.len) {
        return 0;
    }
    if (sep.len == s.len) {
        if (mem.eql(u8, s, sep)) {
            return 1;
        } else {
            return 0;
        }
    }

    var count: usize = 0;
    var i: usize = 0;
    while (mem.indexOf(u8, s[i..], sep)) |idx| {
        count += 1;
        i += idx + sep.len; // Move past the found separator
    }
    return count;
}

test "Count" {
    try testing.expectEqual(@as(usize, 3), Count("banana", "a"));
    try testing.expectEqual(@as(usize, 2), Count("banana", "na"));
    try testing.expectEqual(@as(usize, 1), Count("banana", "b"));
    try testing.expectEqual(@as(usize, 0), Count("banana", "z"));
    try testing.expectEqual(@as(usize, 1), Count("banana", "banana"));
    try testing.expectEqual(@as(usize, 0), Count("banana", "bananas"));
    try testing.expectEqual(@as(usize, 7), Count("banana", "")); // len + 1
    try testing.expectEqual(@as(usize, 1), Count("", ""));
    try testing.expectEqual(@as(usize, 0), Count("", "a"));
}

/// Splits the slice `s` around each instance of one or more consecutive white space
/// characters, as defined by `std.ascii.isSpace`, returning a slice of subslices of `s` or an
/// error if allocation fails.
/// If `s` does not contain any white space characters, or if `s` is empty, it returns
/// a slice containing `s` itself.
/// The caller owns the memory of the returned slice and its elements.
pub fn Fields(allocator: Allocator, s: []const u8) ![][]u8 {
    var list = ArrayList([]u8).init(allocator);
    errdefer list.deinit();

    var start: usize = 0;
    var in_field = false;
    for (s, 0..) |char, i| {
        const is_space = ascii.isSpace(char);
        if (!is_space and !in_field) {
            start = i;
            in_field = true;
        } else if (is_space and in_field) {
            try list.append(try allocator.dupe(u8, s[start..i]));
            in_field = false;
        }
    }
    // Add the last field if it extends to the end
    if (in_field) {
        try list.append(try allocator.dupe(u8, s[start..]));
    }

    // Handle case where input is all spaces or empty
    if (list.items.len == 0 and s.len > 0 and !ascii.isSpace(s[0])) {
        // If no spaces were found but the string isn't empty/all spaces, return the original string
        try list.append(try allocator.dupe(u8, s));
    } else if (list.items.len == 0 and s.len == 0) {
        // If input and output are empty, append an empty slice representation
        try list.append(try allocator.dupe(u8, ""));
    }

    return list.toOwnedSlice();
}

test "Fields" {
    const allocator = testing.allocator;

    var result = try Fields(allocator, "  foo bar  baz   ");
    defer {
        for (result) |item| allocator.free(item);
        allocator.free(result);
    }
    try testing.expectEqualSlices([]const u8, &[_][]const u8{ "foo", "bar", "baz" }, result);

    result = try Fields(allocator, "foo");
    defer {
        for (result) |item| allocator.free(item);
        allocator.free(result);
    }
    try testing.expectEqualSlices([]const u8, &[_][]const u8{"foo"}, result);

    result = try Fields(allocator, "");
    defer {
        for (result) |item| allocator.free(item);
        allocator.free(result);
    }
    // Expecting a slice containing one empty string slice
    try testing.expectEqual(@as(usize, 1), result.len);
    try testing.expectEqualStrings("", result[0]);

    result = try Fields(allocator, "   ");
    defer {
        for (result) |item| allocator.free(item);
        allocator.free(result);
    }
    try testing.expectEqual(@as(usize, 0), result.len); // No fields if all spaces
}

/// Concatenates the elements of `s` to create a new byte slice. The separator `sep`
/// is placed between elements in the resulting slice.
/// The caller owns the returned memory.
pub fn Join(allocator: Allocator, s: [][]const u8, sep: []const u8) ![]u8 {
    if (s.len == 0) {
        return allocator.dupe(u8, "");
    }
    if (s.len == 1) {
        return allocator.dupe(u8, s[0]);
    }

    var total_len: usize = sep.len * (s.len - 1);
    for (s) |item| {
        total_len += item.len;
    }

    var result = try allocator.alloc(u8, total_len);
    errdefer allocator.free(result);

    var current_len: usize = 0;
    for (s, 0..) |item, i| {
        @memcpy(result[current_len..][0..item.len], item);
        current_len += item.len;
        if (i < s.len - 1) {
            @memcpy(result[current_len..][0..sep.len], sep);
            current_len += sep.len;
        }
    }

    return result;
}

test "Join" {
    const allocator = testing.allocator;

    const s1 = &[_][]const u8{ "a", "b", "c" };
    var joined = try Join(allocator, s1, ",");
    defer allocator.free(joined);
    try testing.expectEqualStrings("a,b,c", joined);

    const s2 = &[_][]const u8{ "hello", "world" };
    joined = try Join(allocator, s2, " ");
    defer allocator.free(joined);
    try testing.expectEqualStrings("hello world", joined);

    const s3 = &[_][]const u8{"single"};
    joined = try Join(allocator, s3, ",");
    defer allocator.free(joined);
    try testing.expectEqualStrings("single", joined);

    const s4 = &[_][]const u8{};
    joined = try Join(allocator, s4, ",");
    defer allocator.free(joined);
    try testing.expectEqualStrings("", joined);

    const s5 = &[_][]const u8{ "a", "b" };
    joined = try Join(allocator, s5, "");
    defer allocator.free(joined);
    try testing.expectEqualStrings("ab", joined);

    const s6 = &[_][]const u8{ "", "", "" };
    joined = try Join(allocator, s6, ",");
    defer allocator.free(joined);
    try testing.expectEqualStrings(",,", joined);
}
