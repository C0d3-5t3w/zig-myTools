const std = @import("std");
const math = std.math;
const testing = std.testing;
const builtin = @import("builtin");

// --- Constants ---
// Using f64 for constants, similar to Go's default float type.
pub const E = math.e(f64);
pub const Pi = math.pi(f64);
pub const Phi = (1 + math.sqrt(f64, 5)) / 2; // Golden ratio

pub const Sqrt2 = math.sqrt(f64, 2);
pub const SqrtE = math.sqrt(f64, E);
pub const SqrtPi = math.sqrt(f64, Pi);
pub const SqrtPhi = math.sqrt(f64, Phi);

pub const Ln2 = math.ln2(f64);
pub const Log2E = 1 / Ln2;
pub const Ln10 = math.ln10(f64);
pub const Log10E = 1 / Ln10;

pub const MaxFloat32 = math.floatMax(f32);
pub const SmallestNonzeroFloat32 = math.floatMin(f32); // Smallest positive normal
pub const MaxFloat64 = math.floatMax(f64);
pub const SmallestNonzeroFloat64 = math.floatMin(f64); // Smallest positive normal

// Integer limits depend on the specific integer type in Zig.
// Go's MaxInt/MinInt are platform-dependent (int size).
// We can define them for specific sizes if needed, e.g.:
pub const MaxInt64 = std.math.maxInt(i64);
pub const MinInt64 = std.math.minInt(i64);
pub const MaxUint64 = std.math.maxInt(u64);

// --- Basic Functions ---

/// Returns the absolute value of x.
pub fn Abs(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    return switch (@typeInfo(T)) {
        .Int => |info| if (info.signedness == .signed and x < 0) -x else x,
        .Float => math.fabs(x),
        else => @compileError("Abs requires an integer or float type"),
    };
}

/// Returns the least integer value greater than or equal to x.
pub fn Ceil(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Ceil requires a float type");
    return math.ceil(x);
}

/// Returns the greatest integer value less than or equal to x.
pub fn Floor(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Floor requires a float type");
    return math.floor(x);
}

/// Returns the nearest integer, rounding half away from zero.
pub fn Round(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Round requires a float type");
    // Zig's math.round rounds half to even, Go's rounds half away from zero.
    // Emulate Go's behavior:
    if (x >= 0.0) {
        return math.floor(x + 0.5);
    } else {
        return math.ceil(x - 0.5);
    }
}

/// Returns the integer value nearest to x, rounding halfway cases to the nearest even integer.
pub fn RoundToEven(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("RoundToEven requires a float type");
    return math.round(x); // Zig's default round behavior
}

/// Returns the integer part of x.
pub fn Trunc(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Trunc requires a float type");
    return math.trunc(x);
}

/// Returns the larger of x or y.
pub fn Max(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    return math.max(x, y);
}

/// Returns the smaller of x or y.
pub fn Min(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    return math.min(x, y);
}

// --- Power and Root Functions ---

/// Returns the principal square root of x.
pub fn Sqrt(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Sqrt requires a float type");
    return math.sqrt(x);
}

/// Returns x**y, the base-x exponential of y.
pub fn Pow(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Pow requires a float type");
    return math.pow(T, x, y);
}

/// Returns 10**n.
pub fn Pow10(n_any: anytype) @TypeOf(n_any) {
    const T = @TypeOf(n_any);
    const n = n_any; // Assign to variable 'n' with inferred type T

    return switch (@typeInfo(T)) {
        .Int => |_| {
            // Explicitly cast integer to f64 before passing to math.pow
            const n_float: f64 = @as(f64, n); // Use @as for clarity
            return math.pow(f64, 10.0, n_float); // Return f64 for int input like Go
        },
        .Float => |_| {
            // Use the typed variable 'n'
            return math.pow(T, 10.0, n);
        },
        else => @compileError("Pow10 requires an integer or float type"),
    };
}

// --- Trigonometric Functions ---

pub fn Sin(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Sin requires a float type");
    return math.sin(x);
}
pub fn Cos(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Cos requires a float type");
    return math.cos(x);
}
pub fn Tan(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Tan requires a float type");
    return math.tan(x);
}

// --- Exponential and Logarithmic Functions ---

/// Returns e**x, the base-e exponential of x.
pub fn Exp(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Exp requires a float type");
    return math.exp(x);
}

/// Returns the natural logarithm of x.
pub fn Log(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Log requires a float type");
    return math.log(x);
}

/// Returns the decimal logarithm of x.
pub fn Log10(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Log10 requires a float type");
    return math.log10(x);
}

/// Returns the binary logarithm of x.
pub fn Log2(x: anytype) @TypeOf(x) {
    const T = @TypeOf(x);
    if (@typeInfo(T) != .Float) @compileError("Log2 requires a float type");
    return math.log2(x);
}

// --- Special Values ---

/// Returns a quiet NaN (Not-a-Number) value of the specified float type.
pub fn NaN(comptime T: type) T {
    if (@typeInfo(T) != .Float) @compileError("NaN requires a float type");
    return math.nan(T);
}

/// Returns positive infinity if sign >= 0, negative infinity if sign < 0.
pub fn Inf(comptime T: type, sign: i8) T {
    if (@typeInfo(T) != .Float) @compileError("Inf requires a float type");
    // Simpler way to get +1.0 or -1.0
    const sign_float: T = if (sign >= 0) 1.0 else -1.0;
    return math.inf(T) * sign_float;
}

/// Reports whether f is an infinity, according to sign.
/// sign > 0: positive infinity
/// sign < 0: negative infinity
/// sign == 0: either infinity
pub fn IsInf(f: anytype, sign: i8) bool {
    const T = @TypeOf(f);
    if (@typeInfo(T) != .Float) return false; // Not a float, can't be Inf
    return math.isInf(f) and (sign == 0 or (f > 0 and sign > 0) or (f < 0 and sign < 0));
}

/// Reports whether f is a NaN value.
pub fn IsNaN(f: anytype) bool {
    const T = @TypeOf(f);
    if (@typeInfo(T) != .Float) return false; // Not a float, can't be NaN
    return math.isNan(f);
}

// --- Tests ---
test "Math constants" {
    try testing.expect(E > 2.718 and E < 2.719);
    try testing.expect(Pi > 3.141 and Pi < 3.142);
    try testing.expect(MaxInt64 == 0x7fffffffffffffff);
}

test "Math basic functions" {
    try testing.expectEqual(@as(f32, 1.2), Abs(@as(f32, -1.2)));
    try testing.expectEqual(@as(i32, 5), Abs(@as(i32, -5)));
    try testing.expectEqual(@as(f64, 3.0), Ceil(@as(f64, 2.1)));
    try testing.expectEqual(@as(f64, -2.0), Ceil(@as(f64, -2.9)));
    try testing.expectEqual(@as(f32, 2.0), Floor(@as(f32, 2.9)));
    try testing.expectEqual(@as(f32, -3.0), Floor(@as(f32, -2.1)));
    try testing.expectEqual(@as(f64, 3.0), Round(@as(f64, 2.5))); // Go rounds half away from zero
    try testing.expectEqual(@as(f64, -3.0), Round(@as(f64, -2.5)));
    try testing.expectEqual(@as(f64, 2.0), Round(@as(f64, 2.4)));
    try testing.expectEqual(@as(f64, 2.0), RoundToEven(@as(f64, 2.5))); // Zig rounds half to even
    try testing.expectEqual(@as(f64, 3.0), RoundToEven(@as(f64, 3.5)));
    try testing.expectEqual(@as(f32, 2.0), Trunc(@as(f32, 2.7)));
    try testing.expectEqual(@as(f32, -2.0), Trunc(@as(f32, -2.7)));
    try testing.expectEqual(@as(i32, 5), Max(@as(i32, 5), @as(i32, 3)));
    try testing.expectEqual(@as(f64, 3.0), Min(@as(f64, 5.0), @as(f64, 3.0)));
}

test "Math power/root functions" {
    try testing.expectEqual(@as(f32, 3.0), Sqrt(@as(f32, 9.0)));
    try testing.expectEqual(@as(f64, 8.0), Pow(@as(f64, 2.0), @as(f64, 3.0)));
    try testing.expectEqual(@as(f64, 1000.0), Pow10(@as(i32, 3)));
    try testing.expectEqual(@as(f32, 100.0), Pow10(@as(f32, 2.0)));
}

test "Math trig functions" {
    // Approximate checks
    try testing.expect(math.fabs(Sin(Pi / 6.0) - 0.5) < 1e-9);
    try testing.expect(math.fabs(Cos(Pi / 3.0) - 0.5) < 1e-9);
    try testing.expect(math.fabs(Tan(Pi / 4.0) - 1.0) < 1e-9);
}

test "Math exp/log functions" {
    try testing.expect(math.fabs(Exp(1.0) - E) < 1e-9);
    try testing.expect(math.fabs(Log(E) - 1.0) < 1e-9);
    try testing.expect(math.fabs(Log10(100.0) - 2.0) < 1e-9);
    try testing.expect(math.fabs(Log2(8.0) - 3.0) < 1e-9);
}

test "Math special values" {
    const nan32 = NaN(f32);
    const inf64 = Inf(f64, 1);
    const negInf64 = Inf(f64, -1);

    try testing.expect(IsNaN(nan32));
    try testing.expect(!IsNaN(@as(f32, 1.0)));
    try testing.expect(!IsNaN(@as(i32, 1)));

    try testing.expect(IsInf(inf64, 1));
    try testing.expect(IsInf(inf64, 0));
    try testing.expect(!IsInf(inf64, -1));
    try testing.expect(IsInf(negInf64, -1));
    try testing.expect(IsInf(negInf64, 0));
    try testing.expect(!IsInf(negInf64, 1));
    try testing.expect(!IsInf(@as(f64, 0.0), 0));
    try testing.expect(!IsInf(@as(i32, 0), 0));
}
