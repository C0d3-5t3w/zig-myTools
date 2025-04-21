const std = @import("std");
const time = std.time;
const datetime = std.datetime;
const math = std.math;
const fmt = std.fmt;
const testing = std.testing;
const Allocator = std.mem.Allocator;
const os = std.os;

// --- Duration ---

/// Duration represents the elapsed time between two instants as an int64 nanosecond count.
pub const Duration = i64;

pub const Nanosecond: Duration = 1;
pub const Microsecond: Duration = 1000 * Nanosecond;
pub const Millisecond: Duration = 1000 * Microsecond;
pub const Second: Duration = 1000 * Millisecond;
pub const Minute: Duration = 60 * Second;
pub const Hour: Duration = 60 * Minute;

// --- Time ---

/// Time represents an instant in time with nanosecond precision.
/// Internally stored as nanoseconds since the Unix epoch (January 1, 1970 UTC).
pub const Time = struct {
    nanos: i64, // Nanoseconds since Unix epoch

    /// Returns the current local time.
    pub fn Now() Time {
        const now_ns = time.timestamp();
        return Time{ .nanos = now_ns };
    }

    /// Returns the local Time corresponding to the given Unix time,
    /// sec seconds and nsec nanoseconds since January 1, 1970 UTC.
    /// Renamed from Unix to avoid conflict with the instance method.
    pub fn FromUnix(sec: i64, nsec: i64) Time {
        return Time{ .nanos = sec * Second + nsec };
    }

    /// Returns the local Time corresponding to the given Unix time
    /// represented as nanoseconds since January 1, 1970 UTC.
    /// Renamed from UnixNano to avoid conflict with the instance method.
    pub fn FromUnixNano(nanos_since_epoch: i64) Time {
        return Time{ .nanos = nanos_since_epoch };
    }

    /// Returns the Unix time, the number of nanoseconds elapsed since
    /// January 1, 1970 UTC.
    pub fn UnixNano(self: Time) i64 {
        return self.nanos;
    }

    /// Returns the Unix time, the number of seconds elapsed since
    /// January 1, 1970 UTC.
    pub fn Unix(self: Time) i64 {
        return self.nanos / Second;
    }

    /// Adds the duration d to the time t.
    pub fn Add(self: Time, d: Duration) Time {
        return Time{ .nanos = self.nanos + d };
    }

    /// Returns the duration t-u.
    pub fn Sub(self: Time, u: Time) Duration {
        return self.nanos - u.nanos;
    }

    /// Formats the time according to the layout string.
    /// Uses std.datetime.format. The layout string uses Zig's format specifiers.
    /// Example: "{iso}" for ISO 8601 format.
    /// Note: This requires converting nanos to std.datetime.DateTime.
    /// Assumes UTC for simplicity here. Go's layout is different.
    pub fn Format(self: Time, allocator: Allocator, comptime layout: []const u8) ![]u8 {
        const dt = datetime.DateTime.fromTimestamp(self.Unix());
        // Note: This doesn't include nanoseconds from self.nanos % Second
        // A full implementation would need to handle sub-second precision formatting.
        return fmt.allocPrint(allocator, layout, .{dt});
    }

    /// Returns true if t represents a zero time instant, January 1, year 1, 00:00:00 UTC.
    /// For simplicity, we check if nanos is zero (Unix epoch). Go's zero time is different.
    pub fn IsZero(self: Time) bool {
        return self.nanos == 0;
    }
};

/// Pauses the current goroutine for at least the duration d.
pub fn Sleep(d: Duration) void {
    if (d <= 0) return;
    // time.sleep takes nanoseconds as u64
    time.sleep(@intCast(d));
}

// --- Parsing ---

/// Parses a formatted string and returns the time value it represents.
/// The layout string uses Zig's format specifiers (like std.datetime.parse).
/// Assumes UTC. Go's layout parsing is significantly different.
pub fn Parse(allocator: Allocator, comptime layout: []const u8, value: []const u8) !Time {
    _ = allocator; // Allocator might be needed for more complex parsing later
    const dt = try datetime.parse(layout, value);
    // Note: This loses sub-second precision from the original string.
    return Time.FromUnix(dt.unixTimestamp(), 0);
}

// --- Constants for Layout ---
// These are Zig's std.datetime format specifiers, not Go's layout constants.
pub const LayoutIso = "{iso}"; // Example: 2023-10-27T10:30:00Z
pub const LayoutRfc3339 = "{iso}"; // Similar to ISO 8601
pub const LayoutDateOnly = "{YYYY}-{MM}-{DD}"; // Example: 2023-10-27
pub const LayoutTimeOnly = "{HH}:{mm}:{ss}"; // Example: 10:30:00

// --- Tests ---

test "Duration constants" {
    try testing.expectEqual(@as(Duration, 1), Nanosecond);
    try testing.expectEqual(@as(Duration, 1000), Microsecond);
    try testing.expectEqual(@as(Duration, 1_000_000), Millisecond);
    try testing.expectEqual(@as(Duration, 1_000_000_000), Second);
    try testing.expectEqual(@as(Duration, 60 * 1_000_000_000), Minute);
    try testing.expectEqual(@as(Duration, 3600 * 1_000_000_000), Hour);
}

test "Time Now, Unix, UnixNano" {
    const t1 = Time.Now();
    const unix_nano = t1.UnixNano();
    const unix_sec = t1.Unix();

    try testing.expect(unix_nano > 0);
    try testing.expect(unix_sec > 1600000000); // Ensure it's a reasonable timestamp post-2020

    const t2 = Time.FromUnix(unix_sec, unix_nano % Second);
    try testing.expectEqual(t1.nanos, t2.nanos);

    const t3 = Time.FromUnixNano(unix_nano);
    try testing.expectEqual(t1.nanos, t3.nanos);
}

test "Time Add, Sub" {
    const t1 = Time.FromUnix(1000, 0);
    const d = 5 * Second + 500 * Millisecond;
    const t2 = t1.Add(d);

    try testing.expectEqual(@as(i64, 1005), t2.Unix());
    try testing.expectEqual(@as(i64, 500_000_000), t2.nanos % Second);

    const diff = t2.Sub(t1);
    try testing.expectEqual(d, diff);
}

test "Time IsZero" {
    const zero_time = Time.FromUnix(0, 0);
    const non_zero_time = Time.FromUnix(1, 0);
    try testing.expect(zero_time.IsZero());
    try testing.expect(!non_zero_time.IsZero());
}

test "Sleep" {
    // Test that sleep doesn't block indefinitely for zero/negative duration
    Sleep(0);
    Sleep(-1 * Second);

    // Test a short sleep
    const start = time.timestamp();
    Sleep(10 * Millisecond);
    const end = time.timestamp();
    const elapsed = end - start;
    // Allow for some scheduling delay, check if roughly >= 10ms
    try testing.expect(elapsed >= 9 * Millisecond);
}

test "Time Format" {
    const allocator = testing.allocator;
    // Note: Formatting depends heavily on std.datetime and assumes UTC.
    // It won't capture sub-second precision with this basic implementation.
    const t = Time.FromUnix(1678886461, 123456789); // Approx 2023-03-15 13:21:01 UTC

    // Using ISO format (adjust expected based on your system's std.datetime)
    // This will likely format as 2023-03-15T13:21:01Z or similar
    const formatted_iso = try t.Format(allocator, LayoutIso);
    defer allocator.free(formatted_iso);
    // Check parts, as exact format might vary slightly
    try testing.expect(std.mem.containsAtLeast(u8, formatted_iso, 1, "2023-03-15"));
    try testing.expect(std.mem.containsAtLeast(u8, formatted_iso, 1, "13:21:01"));

    const formatted_date = try t.Format(allocator, LayoutDateOnly);
    defer allocator.free(formatted_date);
    try testing.expectEqualStrings("2023-03-15", formatted_date);

    const formatted_time = try t.Format(allocator, LayoutTimeOnly);
    defer allocator.free(formatted_time);
    try testing.expectEqualStrings("13:21:01", formatted_time);
}

test "Time Parse" {
    const allocator = testing.allocator;
    // Note: Parsing depends on std.datetime and assumes UTC.
    // It won't capture sub-second precision with this basic implementation.

    const t1 = try Parse(allocator, LayoutIso, "2023-03-15T13:21:01Z");
    try testing.expectEqual(@as(i64, 1678886461), t1.Unix());

    const t2 = try Parse(allocator, LayoutDateOnly, "2023-03-15");
    // Unix timestamp for the start of that day UTC
    try testing.expectEqual(@as(i64, 1678838400), t2.Unix());

    // Parsing only time doesn't make sense without a date context for Unix timestamp
    // try Parse(allocator, LayoutTimeOnly, "13:21:01"); // This would likely fail or give unexpected results

    // Test parse error
    try testing.expectError(datetime.ParseError.InvalidFormatSpecifier, Parse(allocator, LayoutIso, "invalid date"));
}
