const std = @import("std");
const mem = std.mem;
const ascii = std.ascii;
const testing = std.testing;

/// Reports whether two slices, `a` and `b`, are equal under Unicode case-folding.
/// This function assumes ASCII case folding for simplicity.
pub fn equalFold(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) {
        return false;
    }
    for (a, 0..) |a_char, i| {
        const b_char = b[i];
        if (a_char == b_char) {
            continue;
        }
        if (ascii.toLower(a_char) != ascii.toLower(b_char)) {
            return false;
        }
    }
    return true;
}

test "equalFold" {
    try testing.expect(equalFold("abc", "abc"));
    try testing.expect(equalFold("abc", "ABC"));
    try testing.expect(equalFold("aBc", "AbC"));
    try testing.expect(!equalFold("abc", "abcd"));
    try testing.expect(!equalFold("abcd", "abc"));
    try testing.expect(!equalFold("abc", "abd"));
    try testing.expect(equalFold("", ""));
    try testing.expect(!equalFold("a", ""));
    try testing.expect(!equalFold("", "a"));
    try testing.expect(equalFold("123", "123"));
    try testing.expect(!equalFold("123", "12a"));
}

/// Returns the index of the last instance of `needle` in `haystack`,
/// or `null` if `needle` is not present in `haystack`.
pub fn lastIndex(comptime T: type, haystack: []const T, needle: []const T) ?usize {
    if (needle.len == 0) {
        return haystack.len; // Consistent with std.mem.indexOf
    }
    if (needle.len > haystack.len) {
        return null;
    }
    var i = haystack.len - needle.len;
    while (true) {
        if (mem.eql(T, haystack[i .. i + needle.len], needle)) {
            return i;
        }
        if (i == 0) {
            break;
        }
        i -= 1;
    }
    return null;
}

test "lastIndex" {
    const haystack_i32 = &[_]i32{ 1, 2, 3, 1, 2, 3, 4 };
    const needle_i32_1 = &[_]i32{ 1, 2 };
    const needle_i32_2 = &[_]i32{ 3, 4 };
    const needle_i32_3 = &[_]i32{5};
    const needle_i32_4 = &[_]i32{};

    try testing.expectEqual(@as(?usize, 3), lastIndex(i32, haystack_i32, needle_i32_1));
    try testing.expectEqual(@as(?usize, 5), lastIndex(i32, haystack_i32, needle_i32_2));
    try testing.expectEqual(@as(?usize, null), lastIndex(i32, haystack_i32, needle_i32_3));
    try testing.expectEqual(@as(?usize, 7), lastIndex(i32, haystack_i32, needle_i32_4));

    const haystack_u8 = "banana";
    const needle_u8_1 = "na";
    const needle_u8_2 = "a";
    const needle_u8_3 = "ban";
    const needle_u8_4 = "z";
    const needle_u8_5 = "";

    try testing.expectEqual(@as(?usize, 4), lastIndex(u8, haystack_u8, needle_u8_1));
    try testing.expectEqual(@as(?usize, 5), lastIndex(u8, haystack_u8, needle_u8_2));
    try testing.expectEqual(@as(?usize, 0), lastIndex(u8, haystack_u8, needle_u8_3));
    try testing.expectEqual(@as(?usize, null), lastIndex(u8, haystack_u8, needle_u8_4));
    try testing.expectEqual(@as(?usize, 6), lastIndex(u8, haystack_u8, needle_u8_5));

    const empty_haystack = "";
    try testing.expectEqual(@as(?usize, null), lastIndex(u8, empty_haystack, "a"));
    try testing.expectEqual(@as(?usize, 0), lastIndex(u8, empty_haystack, ""));
}
