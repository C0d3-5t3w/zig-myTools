const std = @import("std");
const testing = std.testing;
const Order = std.math.Order;
const math = std.math; // Import math

/// Compares two values `x` and `y` of an ordered type `T`.
/// Returns:
///   .lt if x < y
///   .eq if x == y
///   .gt if x > y
/// Requires that the type `T` supports standard comparison operators (<, ==, >).
pub fn Compare(comptime T: type, x: T, y: T) Order {
    if (x < y) {
        return .lt;
    } else if (x > y) {
        return .gt;
    } else {
        // Handles equality and potentially NaN cases for floats where x==y is false.
        // If neither x < y nor x > y is true, they are considered equal in ordering context.
        return .eq;
    }
}

/// Reports whether `x` is less than `y`.
/// Requires that the type `T` supports the less than operator (<).
pub fn Less(comptime T: type, x: T, y: T) bool {
    return x < y;
}

test "Compare" {
    // Integers
    try testing.expect(Compare(i32, 1, 2) == .lt);
    try testing.expect(Compare(i32, 2, 1) == .gt);
    try testing.expect(Compare(i32, 1, 1) == .eq);
    try testing.expect(Compare(u64, 100, 50) == .gt);

    // Floats
    try testing.expect(Compare(f32, 1.0, 2.0) == .lt);
    try testing.expect(Compare(f32, 2.0, 1.0) == .gt);
    try testing.expect(Compare(f32, 1.0, 1.0) == .eq);
    // Note: NaN comparison behavior depends on the underlying operators.
    // Zig's standard float comparisons handle NaN according to IEEE 754.
    const nan32 = math.nan(f32); // Use std.math.nan
    try testing.expect(Compare(f32, nan32, 1.0) == .eq); // NaN is unordered, neither < nor > is true
    try testing.expect(Compare(f32, 1.0, nan32) == .eq);
    try testing.expect(Compare(f32, nan32, nan32) == .eq);

    // Chars
    try testing.expect(Compare(u8, 'a', 'b') == .lt);
    try testing.expect(Compare(u8, 'b', 'a') == .gt);
    try testing.expect(Compare(u8, 'a', 'a') == .eq);
}

test "Less" {
    // Integers
    try testing.expect(Less(i32, 1, 2));
    try testing.expect(!Less(i32, 2, 1));
    try testing.expect(!Less(i32, 1, 1));

    // Floats
    try testing.expect(Less(f64, 1.5, 2.5));
    try testing.expect(!Less(f64, 2.5, 1.5));
    try testing.expect(!Less(f64, 1.5, 1.5));
    const nan64 = math.nan(f64); // Use std.math.nan
    try testing.expect(!Less(f64, nan64, 1.0)); // NaN comparisons are false
    try testing.expect(!Less(f64, 1.0, nan64));
    try testing.expect(!Less(f64, nan64, nan64));

    // Chars
    try testing.expect(Less(u8, 'x', 'y'));
    try testing.expect(!Less(u8, 'y', 'x'));
    try testing.expect(!Less(u8, 'x', 'x'));
}
