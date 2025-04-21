const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const Allocator = mem.Allocator;
const ascii = std.ascii;

/// Reverses a copy of the input string `s`.
/// The caller owns the returned memory.
pub fn reverse(allocator: Allocator, s: []const u8) ![]u8 {
    const len = s.len;
    const buf = try allocator.alloc(u8, len);
    errdefer allocator.free(buf);

    for (s, 0..) |char, i| {
        buf[len - 1 - i] = char;
    }
    return buf;
}

test "reverse string" {
    const allocator = testing.allocator;
    const original = "hello";
    const reversed = try reverse(allocator, original);
    defer allocator.free(reversed);
    try testing.expectEqualStrings("olleh", reversed);

    const empty = "";
    const reversed_empty = try reverse(allocator, empty);
    defer allocator.free(reversed_empty);
    try testing.expectEqualStrings("", reversed_empty);
}

/// Returns a slice of `s` with all leading and trailing characters contained in `cutset` removed.
pub fn trim(s: []const u8, cutset: []const u8) []const u8 {
    var start: usize = 0;
    while (start < s.len and mem.containsAtLeast(u8, cutset, 1, s[start .. start + 1])) : (start += 1) {}

    var end: usize = s.len;
    while (end > start and mem.containsAtLeast(u8, cutset, 1, s[end - 1 .. end])) : (end -= 1) {}

    return s[start..end];
}

test "trim string" {
    const cutset = " \t\n\r";
    try testing.expectEqualStrings("hello world", trim("  hello world  ", cutset));
    try testing.expectEqualStrings("hello world", trim("hello world", cutset));
    try testing.expectEqualStrings("", trim("   ", cutset));
    try testing.expectEqualStrings("h", trim(" h ", cutset));
    try testing.expectEqualStrings("hello", trim("\thello\n", cutset));
}

/// Reports whether `s` begins with `prefix`.
pub fn startsWith(s: []const u8, prefix: []const u8) bool {
    return mem.startsWith(u8, s, prefix);
}

test "startsWith" {
    try testing.expect(startsWith("hello world", "hello"));
    try testing.expect(!startsWith("hello world", "world"));
    try testing.expect(startsWith("abc", ""));
    try testing.expect(startsWith("", ""));
    try testing.expect(!startsWith("", "a"));
}

/// Reports whether `s` ends with `suffix`.
pub fn endsWith(s: []const u8, suffix: []const u8) bool {
    return mem.endsWith(u8, s, suffix);
}

test "endsWith" {
    try testing.expect(endsWith("hello world", "world"));
    try testing.expect(!endsWith("hello world", "hello"));
    try testing.expect(endsWith("abc", ""));
    try testing.expect(endsWith("", ""));
    try testing.expect(!endsWith("", "a"));
}

/// Returns a copy of the string `s` with all Unicode letters mapped to their upper case.
/// The caller owns the returned memory.
pub fn toUpperCase(allocator: Allocator, s: []const u8) ![]u8 {
    const buf = try allocator.alloc(u8, s.len);
    errdefer allocator.free(buf);
    for (s, 0..) |char, i| {
        buf[i] = ascii.toUpper(char);
    }
    return buf;
}

test "toUpperCase" {
    const allocator = testing.allocator;
    const original = "Hello World 123";
    const upper = try toUpperCase(allocator, original);
    defer allocator.free(upper);
    try testing.expectEqualStrings("HELLO WORLD 123", upper);

    const empty = "";
    const upper_empty = try toUpperCase(allocator, empty);
    defer allocator.free(upper_empty);
    try testing.expectEqualStrings("", upper_empty);
}

/// Returns a copy of the string `s` with all Unicode letters mapped to their lower case.
/// The caller owns the returned memory.
pub fn toLowerCase(allocator: Allocator, s: []const u8) ![]u8 {
    const buf = try allocator.alloc(u8, s.len);
    errdefer allocator.free(buf);
    for (s, 0..) |char, i| {
        buf[i] = ascii.toLower(char);
    }
    return buf;
}

test "toLowerCase" {
    const allocator = testing.allocator;
    const original = "Hello World 123";
    const lower = try toLowerCase(allocator, original);
    defer allocator.free(lower);
    try testing.expectEqualStrings("hello world 123", lower);

    const empty = "";
    const lower_empty = try toLowerCase(allocator, empty);
    defer allocator.free(lower_empty);
    try testing.expectEqualStrings("", lower_empty);
}

/// Reports whether `s` reads the same forwards and backwards.
/// Note: This is a simple byte-wise comparison. It may not work as expected
/// for multi-byte Unicode characters or characters with different representations (e.g., accents).
pub fn isPalindrome(s: []const u8) bool {
    const len = s.len;
    if (len == 0) return true;
    var i: usize = 0;
    while (i < len / 2) : (i += 1) {
        if (s[i] != s[len - 1 - i]) {
            return false;
        }
    }
    return true;
}

test "isPalindrome" {
    try testing.expect(isPalindrome(""));
    try testing.expect(isPalindrome("a"));
    try testing.expect(isPalindrome("racecar"));
    try testing.expect(isPalindrome("madam"));
    try testing.expect(!isPalindrome("hello"));
    try testing.expect(!isPalindrome("Racecar")); // Case-sensitive
}
