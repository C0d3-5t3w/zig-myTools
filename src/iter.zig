const std = @import("std");
const testing = std.testing;

/// An iterator that yields numbers from 0 up to (but not including) `end`.
pub const RangeIterator = struct {
    current: usize = 0,
    end: usize,

    pub fn next(self: *RangeIterator) ?usize {
        if (self.current < self.end) {
            const value = self.current;
            self.current += 1;
            return value;
        } else {
            return null;
        }
    }
};

/// Returns an iterator (RangeIterator) that yields values from 0 up to n-1.
/// This mimics Go's iter.N concept.
pub fn Seq(n: usize) RangeIterator {
    return RangeIterator{ .end = n };
}

// TODO: Add iterators for slices, maps, etc.
// TODO: Add functions like All, Pull, etc. (would require function pointers/interfaces)

test "Seq iterator" {
    var iter5 = Seq(5);
    try testing.expectEqual(@as(?usize, 0), iter5.next());
    try testing.expectEqual(@as(?usize, 1), iter5.next());
    try testing.expectEqual(@as(?usize, 2), iter5.next());
    try testing.expectEqual(@as(?usize, 3), iter5.next());
    try testing.expectEqual(@as(?usize, 4), iter5.next());
    try testing.expectEqual(@as(?usize, null), iter5.next());
    try testing.expectEqual(@as(?usize, null), iter5.next()); // Check exhaustion

    var iter0 = Seq(0);
    try testing.expectEqual(@as(?usize, null), iter0.next());

    var iter1 = Seq(1);
    try testing.expectEqual(@as(?usize, 0), iter1.next());
    try testing.expectEqual(@as(?usize, null), iter1.next());
}
