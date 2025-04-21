const std = @import("std");
const thread = std.Thread;
const atomic = std.atomic;
const testing = std.testing;
const Allocator = std.mem.Allocator;

// --- sync package equivalents ---

/// Mutex corresponds to std.Thread.Mutex.
pub const Mutex = thread.Mutex;

/// RWMutex corresponds to std.Thread.RwLock.
pub const RWMutex = thread.RwLock;

/// Cond corresponds to std.Thread.Condition.
pub const Cond = thread.Condition;

/// WaitGroup waits for a collection of threads to complete.
pub const WaitGroup = struct {
    mutex: Mutex = .{},
    cond: Cond = .{},
    count: i64 = 0,

    /// Adds delta, which may be negative, to the WaitGroup counter.
    /// If the counter becomes zero, all threads blocked on Wait are released.
    /// If the counter becomes negative, it panics.
    pub fn add(self: *WaitGroup, delta: i64) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.count += delta;
        if (self.count < 0) {
            @panic("negative WaitGroup counter");
        }

        if (self.count == 0) {
            // Signal all waiting threads
            self.cond.broadcast();
        }
    }

    /// Decrements the WaitGroup counter by one.
    pub fn done(self: *WaitGroup) void {
        self.add(-1);
    }

    /// Blocks until the WaitGroup counter is zero.
    pub fn wait(self: *WaitGroup) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        while (self.count > 0) {
            self.cond.wait(&self.mutex);
        }
    }
};

/// Once is an object that will perform exactly one action.
pub const Once = struct {
    // 0 = initial, 1 = running, 2 = done
    state: atomic.Atomic(u8) = atomic.Atomic(u8).init(0),
    mutex: Mutex = .{}, // Mutex for waiting if another thread is running `do`

    /// Calls the function f exactly once.
    pub fn do(self: *Once, f: fn () void) void {
        // Fast path: check if already done
        if (self.state.load(.Acquire) == 2) {
            return;
        }

        // Try to transition from initial (0) to running (1)
        if (self.state.cmpxchgStrong(.initial, .running, .AcqRel, .Acquire) != null) {
            // We successfully transitioned to running, execute the function
            defer {
                // Mark as done (2) after execution
                _ = self.state.store(.done, .Release);
                // Wake up any waiters
                self.mutex.lock();
                self.mutex.unlock(); // Effectively signals completion via mutex availability
            }
            f();
        } else {
            // Another thread is running or has finished.
            // Wait until the state is 'done'.
            // We use a simple spin-wait with a mutex lock attempt for yielding.
            // A more sophisticated approach might use a condition variable.
            while (self.state.load(.Acquire) != 2) {
                // Attempt to lock/unlock the mutex briefly to potentially yield
                self.mutex.lock();
                self.mutex.unlock();
                // Optional: thread.yield() or sleep briefly
            }
        }
    }

    comptime {
        // Define state constants within the struct scope
        _ = @import("std").meta.DeclEnum(Once, .{
            .initial = 0,
            .running = 1,
            .done = 2,
        });
    }
};

// --- sync/atomic package equivalents ---

// We provide functions mirroring Go's atomic API for specific types.
// Go uses uintptr, i32, u32, i64, u64, unsafe.Pointer.
// Zig uses usize, isize, and specific integer types. We'll focus on 64-bit
// integers, bool, and opaque pointers (*anyopaque) for demonstration.
// Default memory order is SeqCst, matching Go's default.

// -- Bool --
pub fn CompareAndSwapBool(addr: *atomic.Atomic(bool), old: bool, new: bool) bool {
    return addr.cmpxchgStrong(old, new, .SeqCst, .SeqCst) == null;
}
pub fn LoadBool(addr: *const atomic.Atomic(bool)) bool {
    return addr.load(.SeqCst);
}
pub fn StoreBool(addr: *atomic.Atomic(bool), val: bool) void {
    addr.store(val, .SeqCst);
}
pub fn SwapBool(addr: *atomic.Atomic(bool), new: bool) bool {
    return addr.swap(new, .SeqCst);
}

// -- Int64 --
pub fn AddI64(addr: *atomic.Atomic(i64), delta: i64) i64 {
    return addr.fetchAdd(delta, .SeqCst) + delta; // Go returns the new value
}
pub fn CompareAndSwapI64(addr: *atomic.Atomic(i64), old: i64, new: i64) bool {
    return addr.cmpxchgStrong(old, new, .SeqCst, .SeqCst) == null;
}
pub fn LoadI64(addr: *const atomic.Atomic(i64)) i64 {
    return addr.load(.SeqCst);
}
pub fn StoreI64(addr: *atomic.Atomic(i64), val: i64) void {
    addr.store(val, .SeqCst);
}
pub fn SwapI64(addr: *atomic.Atomic(i64), new: i64) i64 {
    return addr.swap(new, .SeqCst);
}

// -- Uint64 --
pub fn AddU64(addr: *atomic.Atomic(u64), delta: u64) u64 {
    return addr.fetchAdd(delta, .SeqCst) + delta; // Go returns the new value
}
pub fn CompareAndSwapU64(addr: *atomic.Atomic(u64), old: u64, new: u64) bool {
    return addr.cmpxchgStrong(old, new, .SeqCst, .SeqCst) == null;
}
pub fn LoadU64(addr: *const atomic.Atomic(u64)) u64 {
    return addr.load(.SeqCst);
}
pub fn StoreU64(addr: *atomic.Atomic(u64), val: u64) void {
    addr.store(val, .SeqCst);
}
pub fn SwapU64(addr: *atomic.Atomic(u64), new: u64) u64 {
    return addr.swap(new, .SeqCst);
}

// -- Pointer (*anyopaque) --
// Note: Go uses unsafe.Pointer. Zig uses typed pointers or *anyopaque.
pub fn CompareAndSwapPointer(addr: *atomic.Atomic(?*anyopaque), old: ?*anyopaque, new: ?*anyopaque) bool {
    return addr.cmpxchgStrong(old, new, .SeqCst, .SeqCst) == null;
}
pub fn LoadPointer(addr: *const atomic.Atomic(?*anyopaque)) ?*anyopaque {
    return addr.load(.SeqCst);
}
pub fn StorePointer(addr: *atomic.Atomic(?*anyopaque), val: ?*anyopaque) void {
    addr.store(val, .SeqCst);
}
pub fn SwapPointer(addr: *atomic.Atomic(?*anyopaque), new: ?*anyopaque) ?*anyopaque {
    return addr.swap(new, .SeqCst);
}

// --- Tests ---

test "WaitGroup" {
    var wg = WaitGroup{};
    const n_threads = 5;
    var counter = atomic.Atomic(u32).init(0);

    wg.add(n_threads);

    var i: usize = 0;
    while (i < n_threads) : (i += 1) {
        _ = try thread.spawn(.{}, struct {
            fn run(wg_ptr: *WaitGroup, counter_ptr: *atomic.Atomic(u32)) void {
                defer wg_ptr.done();
                _ = counter_ptr.fetchAdd(1, .SeqCst);
                // Simulate work
                thread.yield();
            }
        }.run, .{ &wg, &counter });
    }

    wg.wait(); // Wait for all threads to finish

    try testing.expectEqual(@as(u32, n_threads), counter.load(.SeqCst));
    try testing.expectEqual(@as(i64, 0), wg.count);
}

test "Once" {
    var once = Once{};
    var counter: u32 = 0;

    const func = struct {
        fn increment(counter_ptr: *u32) void {
            counter_ptr.* += 1;
        }
    }.increment;

    const n_threads = 10;
    var threads: [n_threads]thread.JoinHandle = undefined;

    var i: usize = 0;
    while (i < n_threads) : (i += 1) {
        threads[i] = try thread.spawn(.{}, struct {
            fn run(once_ptr: *Once, counter_ptr: *u32, f: fn (*u32) void) void {
                once_ptr.do(struct {
                    fn wrapper(c: *u32, inner_f: fn (*u32) void) void {
                        inner_f(c);
                    }
                }.wrapper, .{ counter_ptr, f });
            }
        }.run, .{ &once, &counter, func });
    }

    // Wait for all threads
    i = 0;
    while (i < n_threads) : (i += 1) {
        threads[i].join();
    }

    // The function should have been executed exactly once
    try testing.expectEqual(@as(u32, 1), counter);
    try testing.expectEqual(@as(u8, 2), once.state.load(.SeqCst)); // State should be 'done'
}

test "Atomics" {
    // Bool
    var ab = atomic.Atomic(bool).init(false);
    try testing.expectEqual(false, LoadBool(&ab));
    StoreBool(&ab, true);
    try testing.expectEqual(true, LoadBool(&ab));
    try testing.expectEqual(true, SwapBool(&ab, false));
    try testing.expectEqual(false, LoadBool(&ab));
    try testing.expect(CompareAndSwapBool(&ab, false, true));
    try testing.expectEqual(true, LoadBool(&ab));
    try testing.expect(!CompareAndSwapBool(&ab, false, true)); // Should fail
    try testing.expectEqual(true, LoadBool(&ab));

    // I64
    var ai64 = atomic.Atomic(i64).init(10);
    try testing.expectEqual(@as(i64, 10), LoadI64(&ai64));
    StoreI64(&ai64, 20);
    try testing.expectEqual(@as(i64, 20), LoadI64(&ai64));
    try testing.expectEqual(@as(i64, 25), AddI64(&ai64, 5));
    try testing.expectEqual(@as(i64, 25), LoadI64(&ai64));
    try testing.expectEqual(@as(i64, 20), AddI64(&ai64, -5));
    try testing.expectEqual(@as(i64, 20), LoadI64(&ai64));
    try testing.expectEqual(@as(i64, 20), SwapI64(&ai64, 30));
    try testing.expectEqual(@as(i64, 30), LoadI64(&ai64));
    try testing.expect(CompareAndSwapI64(&ai64, 30, 40));
    try testing.expectEqual(@as(i64, 40), LoadI64(&ai64));
    try testing.expect(!CompareAndSwapI64(&ai64, 30, 50));
    try testing.expectEqual(@as(i64, 40), LoadI64(&ai64));

    // U64
    var au64 = atomic.Atomic(u64).init(100);
    try testing.expectEqual(@as(u64, 100), LoadU64(&au64));
    StoreU64(&au64, 200);
    try testing.expectEqual(@as(u64, 200), LoadU64(&au64));
    try testing.expectEqual(@as(u64, 250), AddU64(&au64, 50));
    try testing.expectEqual(@as(u64, 250), LoadU64(&au64));
    try testing.expectEqual(@as(u64, 250), SwapU64(&au64, 300));
    try testing.expectEqual(@as(u64, 300), LoadU64(&au64));
    try testing.expect(CompareAndSwapU64(&au64, 300, 400));
    try testing.expectEqual(@as(u64, 400), LoadU64(&au64));
    try testing.expect(!CompareAndSwapU64(&au64, 300, 500));
    try testing.expectEqual(@as(u64, 400), LoadU64(&au64));

    // Pointer
    var val1: u32 = 1;
    var val2: u32 = 2;
    var val3: u32 = 3;
    const ptr1: *anyopaque = &val1;
    const ptr2: *anyopaque = &val2;
    const ptr3: *anyopaque = &val3;

    var ap = atomic.Atomic(?*anyopaque).init(null);
    try testing.expectEqual(null, LoadPointer(&ap));
    StorePointer(&ap, ptr1);
    try testing.expectEqual(ptr1, LoadPointer(&ap));
    try testing.expectEqual(ptr1, SwapPointer(&ap, ptr2));
    try testing.expectEqual(ptr2, LoadPointer(&ap));
    try testing.expect(CompareAndSwapPointer(&ap, ptr2, ptr3));
    try testing.expectEqual(ptr3, LoadPointer(&ap));
    try testing.expect(!CompareAndSwapPointer(&ap, ptr2, ptr1));
    try testing.expectEqual(ptr3, LoadPointer(&ap));
    StorePointer(&ap, null);
    try testing.expectEqual(null, LoadPointer(&ap));
}
