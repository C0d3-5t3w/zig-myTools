//! WARNING: Inline assembly is target-specific and unsafe.
//! The functions in this module are primarily for x86-64 architectures
//! using the System V AMD64 ABI (e.g., Linux, macOS).
//! They may not work or may crash on other systems.

const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;
const os = std.os; // Needed for syscall numbers

/// Executes the CPUID instruction on x86/x86-64.
/// Takes the initial EAX value (leaf) as input.
/// Returns the EAX, EBX, ECX, and EDX registers as output.
/// Returns null if not on x86/x86-64 architecture.
pub fn cpuid(leaf: u32) ?struct { eax: u32, ebx: u32, ecx: u32, edx: u32 } {
    if (builtin.cpu.arch != .x86_64 and builtin.cpu.arch != .x86) {
        return null;
    }

    var eax: u32 = leaf;
    var ebx: u32 = undefined;
    var ecx: u32 = 0; // Some leaves require ECX to be set (e.g., 7)
    var edx: u32 = undefined;

    // Use asm volatile to prevent reordering/optimization.
    asm volatile ("cpuid"
        : [eax_out] "+{rax}" (eax),
          [ebx_out] "={rbx}" (ebx),
          [ecx_out] "+{rcx}" (ecx),
          [edx_out] "={rdx}" (edx),
        : [eax_in] "{rax}" (leaf),
        : "cc"
    );

    return .{ .eax = eax, .ebx = ebx, .ecx = ecx, .edx = edx };
}

/// Simple addition using inline assembly (x86-64).
/// Adds y to x and returns the result.
/// Returns null if not on x86-64.
pub fn addU64(x: u64, y: u64) ?u64 {
    if (builtin.cpu.arch != .x86_64) {
        return null;
    }
    var result: u64 = x;
    asm volatile ("add %[y], %[r]"
        : [r] "+r" (result),
        : [y] "r" (y),
        : "cc"
    );
    return result;
}

/// Simple subtraction using inline assembly (x86-64).
/// Subtracts y from x (x - y) and returns the result.
/// Returns null if not on x86-64.
pub fn subU64(x: u64, y: u64) ?u64 {
    if (builtin.cpu.arch != .x86_64) {
        return null;
    }
    var result: u64 = x;
    asm volatile ("sub %[y], %[r]"
        : [r] "+r" (result),
        : [y] "r" (y),
        : "cc"
    );
    return result;
}

/// Atomically adds `delta` to the value pointed to by `ptr` (x86-64).
/// Uses `lock add` instruction.
/// Returns null if not on x86-64.
/// WARNING: Modifies memory directly. Ensure `ptr` is valid and properly aligned.
pub fn atomicAddU64(ptr: *volatile u64, delta: u64) ?void {
    if (builtin.cpu.arch != .x86_64) {
        return null;
    }

    // Pass the pointer as a register input and use register indirect addressing
    asm volatile ("lock add %[d], (%[p])" // Use register indirect addressing: add delta to memory at address in register p
        : // No direct memory output operand needed here
        : [p] "r" (ptr), // Input: pointer in any general-purpose register
          [d] "r" (delta), // Input: delta in any general-purpose register
        : "cc", "memory" // Clobbers: condition codes and memory
    );
}

/// Performs a Linux x86-64 syscall with 3 arguments.
/// Returns the result from RAX, or null if not on Linux x86-64.
/// WARNING: Extremely unsafe and non-portable. Behavior depends entirely on the OS kernel ABI.
pub fn syscall3(syscall_num: u64, arg1: u64, arg2: u64, arg3: u64) ?u64 {
    // Check for Linux on x86-64
    if (builtin.os.tag != .linux or builtin.cpu.arch != .x86_64) {
        return null;
    }

    var ret: u64 = syscall_num; // Syscall number goes into RAX initially

    // System V AMD64 ABI for syscalls:
    // RAX: syscall number (input), return value (output)
    // RDI: arg1
    // RSI: arg2
    // RDX: arg3
    // RCX, R11 are clobbered by syscall instruction
    asm volatile ("syscall"
        : [ret] "+{rax}" (ret),
        : [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
        : "rcx", "r11", "memory"
    );
    return ret;
}

test "cpuid basic functionality" {
    // This test assumes x86-64 architecture. Skip otherwise.
    if (builtin.cpu.arch != .x86_64 and builtin.cpu.arch != .x86) {
        std.debug.print("Skipping cpuid test on non-x86 architecture\n", .{});
        return error.SkipZigTest;
    }

    // Leaf 0: Get vendor string
    const result0 = cpuid(0) orelse return error.SkipZigTest;
    try testing.expect(result0.eax >= 0); // Max leaf should be non-negative

    // Check if vendor string parts seem reasonable (ASCII)
    var vendor_bytes: [12]u8 = undefined;
    std.mem.writeInt(u32, vendor_bytes[0..4], result0.ebx, .little);
    std.mem.writeInt(u32, vendor_bytes[4..8], result0.edx, .little); // Order is EBX, EDX, ECX
    std.mem.writeInt(u32, vendor_bytes[8..12], result0.ecx, .little);

    std.debug.print("\nCPU Vendor: {s}\n", .{vendor_bytes});
    for (vendor_bytes) |byte| {
        try testing.expect(std.ascii.isPrint(byte) or byte == 0);
    }

    // Leaf 1: Processor Info and Feature Bits
    const result1 = cpuid(1) orelse return error.SkipZigTest;
    try testing.expect(result1.eax != 0); // Basic processor info should exist
}

test "addU64 assembly" {
    // This test assumes x86-64 architecture. Skip otherwise.
    if (builtin.cpu.arch != .x86_64) {
        std.debug.print("Skipping addU64 test on non-x86_64 architecture\n", .{});
        return error.SkipZigTest;
    }

    const res1 = addU64(5, 3) orelse return error.SkipZigTest;
    try testing.expectEqual(@as(u64, 8), res1);

    const res2 = addU64(0, 0) orelse return error.SkipZigTest;
    try testing.expectEqual(@as(u64, 0), res2);

    const res3 = addU64(std.math.maxInt(u64), 0) orelse return error.SkipZigTest;
    try testing.expectEqual(std.math.maxInt(u64), res3);

    // Test overflow (assembly add will wrap)
    const res4 = addU64(std.math.maxInt(u64), 1) orelse return error.SkipZigTest;
    try testing.expectEqual(@as(u64, 0), res4);
}

test "subU64 assembly" {
    // This test assumes x86-64 architecture. Skip otherwise.
    if (builtin.cpu.arch != .x86_64) {
        std.debug.print("Skipping subU64 test on non-x86_64 architecture\n", .{});
        return error.SkipZigTest;
    }

    const res1 = subU64(5, 3) orelse return error.SkipZigTest;
    try testing.expectEqual(@as(u64, 2), res1);

    const res2 = subU64(10, 10) orelse return error.SkipZigTest;
    try testing.expectEqual(@as(u64, 0), res2);

    // Test underflow (assembly sub will wrap)
    const res3 = subU64(0, 1) orelse return error.SkipZigTest;
    try testing.expectEqual(std.math.maxInt(u64), res3);

    const res4 = subU64(std.math.maxInt(u64), std.math.maxInt(u64)) orelse return error.SkipZigTest;
    try testing.expectEqual(@as(u64, 0), res4);
}

test "atomicAddU64 assembly" {
    // This test assumes x86-64 architecture. Skip otherwise.
    if (builtin.cpu.arch != .x86_64) {
        std.debug.print("Skipping atomicAddU64 test on non-x86_64 architecture\n", .{});
        return error.SkipZigTest;
    }

    var value: u64 = 10;
    atomicAddU64(&value, 5) orelse return error.SkipZigTest;
    try testing.expectEqual(@as(u64, 15), value);

    atomicAddU64(&value, 0) orelse return error.SkipZigTest;
    try testing.expectEqual(@as(u64, 15), value);

    // Test with potential overflow (should wrap atomically)
    value = std.math.maxInt(u64) - 2;
    atomicAddU64(&value, 5) orelse return error.SkipZigTest; // (max - 2) + 5 = max + 3 = 2
    try testing.expectEqual(@as(u64, 2), value);
}

test "syscall3 assembly (Linux x86-64 only)" {
    // This test assumes Linux on x86-64. Skip otherwise.
    if (builtin.os.tag != .linux or builtin.cpu.arch != .x86_64) {
        std.debug.print("Skipping syscall3 test on non-Linux/x86-64\n", .{});
        return error.SkipZigTest;
    }

    // Use a safe syscall like getpid() which takes no arguments but fits the pattern.
    // We pass dummy args which should be ignored by getpid.
    // Note: Syscall numbers can vary slightly, but getpid is usually stable.
    const getpid_num = os.linux.SYS_getpid;
    const pid_asm = syscall3(getpid_num, 0, 0, 0) orelse return error.SkipZigTest;

    // Get PID using standard library for comparison
    const pid_std = os.getpid();

    std.debug.print("\nPID (asm): {d}, PID (std): {d}\n", .{ pid_asm, pid_std });
    try testing.expect(pid_asm > 0);
    try testing.expectEqual(pid_std, @intCast(pid_asm));

    // Example of write syscall (use with caution, writes to stderr)
    // const write_num = os.linux.SYS_write;
    // const stderr_fd: u64 = 2;
    // const msg = "Syscall test\n";
    // const msg_ptr: u64 = @intFromPtr(msg.ptr);
    // const msg_len: u64 = msg.len;
    // const bytes_written = syscall3(write_num, stderr_fd, msg_ptr, msg_len) orelse return error.SkipZigTest;
    // try testing.expectEqual(msg.len, bytes_written);
}
