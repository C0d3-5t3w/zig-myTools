//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

// Import the new strings module
pub const zstrings = @import("strings.zig");
// Import the new net module
pub const znet = @import("net.zig");
// Import the new http module
pub const zhttp = @import("http.zig");
// Import the new zmt module
pub const zmt = @import("zmt.zig");
// Import the new slices module
pub const zslices = @import("slices.zig");
// Import the new ws module
pub const zws = @import("ws.zig");
// Import the new mem module (as zmem to avoid conflict)
pub const zmem = @import("mem.zig");
// Import the new allocator module (as zallocator)
pub const zallocator = @import("allocator.zig");
// Import the new sort module (as zsort)
pub const zsort = @import("sort.zig");
// Import the new bytes module (as zbytes)
pub const zbytes = @import("bytes.zig");
// Import the new cmp module (as zcmp)
pub const zcmp = @import("cmp.zig");
// Import the new iter module (as ziter)
pub const ziter = @import("iter.zig");
// Import the new async module (as zasync)
pub const zasync = @import("async.zig");
// Import the new math module (as zmath)
pub const zmath = @import("math.zig");
// Import the new io module (as zio)
pub const zio = @import("io.zig");
// Import the new reflect module (as zreflect)
pub const zreflect = @import("reflect.zig");
// Import the new time module (as ztime)
pub const ztime = @import("time.zig");
// Import the new asm module (as zasm)
pub const zasm = @import("asm.zig");

// Re-export functions from strings.zig
pub const reverse = zstrings.reverse;
pub const trim = zstrings.trim;
pub const startsWith = zstrings.startsWith;
pub const endsWith = zstrings.endsWith;
pub const toUpperCase = zstrings.toUpperCase;
pub const toLowerCase = zstrings.toLowerCase;
pub const isPalindrome = zstrings.isPalindrome;

// Re-export functions from zmem
pub const equalFold = zmem.equalFold;
pub const lastIndex = zmem.lastIndex;

// Re-export types/functions from zallocator
pub const CountingAllocator = zallocator.CountingAllocator;
pub const LimitedAllocator = zallocator.LimitedAllocator;

// Re-export functions from zsort
pub const isSorted = zsort.isSorted;
pub const Search = zsort.Search;

// Re-export functions from zbytes
pub const Compare = zbytes.Compare;
pub const Contains = zbytes.Contains;
pub const Count = zbytes.Count;
pub const Fields = zbytes.Fields;
pub const Join = zbytes.Join;

// Re-export functions from zcmp
pub const CmpCompare = zcmp.Compare; // Renamed to avoid conflict with zbytes.Compare
pub const CmpLess = zcmp.Less;

// Re-export functions/types from ziter
pub const Seq = ziter.Seq;
pub const RangeIterator = ziter.RangeIterator;

// Re-export types/functions from zasync
pub const Mutex = zasync.Mutex;
pub const RWMutex = zasync.RWMutex;
pub const Cond = zasync.Cond;
pub const WaitGroup = zasync.WaitGroup;
pub const Once = zasync.Once;
// Atomics
pub const CompareAndSwapBool = zasync.CompareAndSwapBool;
pub const LoadBool = zasync.LoadBool;
pub const StoreBool = zasync.StoreBool;
pub const SwapBool = zasync.SwapBool;
pub const AddI64 = zasync.AddI64;
pub const CompareAndSwapI64 = zasync.CompareAndSwapI64;
pub const LoadI64 = zasync.LoadI64;
pub const StoreI64 = zasync.StoreI64;
pub const SwapI64 = zasync.SwapI64;
pub const AddU64 = zasync.AddU64;
pub const CompareAndSwapU64 = zasync.CompareAndSwapU64;
pub const LoadU64 = zasync.LoadU64;
pub const StoreU64 = zasync.StoreU64;
pub const SwapU64 = zasync.SwapU64;
pub const CompareAndSwapPointer = zasync.CompareAndSwapPointer;
pub const LoadPointer = zasync.LoadPointer;
pub const StorePointer = zasync.StorePointer;
pub const SwapPointer = zasync.SwapPointer;

// Re-export constants/functions from zmath
pub const E = zmath.E;
pub const Pi = zmath.Pi;
pub const Phi = zmath.Phi;
pub const Sqrt2 = zmath.Sqrt2;
pub const Ln2 = zmath.Ln2;
pub const Ln10 = zmath.Ln10;
pub const Log2E = zmath.Log2E;
pub const Log10E = zmath.Log10E;
pub const MaxFloat32 = zmath.MaxFloat32;
pub const SmallestNonzeroFloat32 = zmath.SmallestNonzeroFloat32;
pub const MaxFloat64 = zmath.MaxFloat64;
pub const SmallestNonzeroFloat64 = zmath.SmallestNonzeroFloat64;
pub const MaxInt64 = zmath.MaxInt64;
pub const MinInt64 = zmath.MinInt64;
pub const MaxUint64 = zmath.MaxUint64;
pub const Abs = zmath.Abs;
pub const Ceil = zmath.Ceil;
pub const Floor = zmath.Floor;
pub const Round = zmath.Round;
pub const RoundToEven = zmath.RoundToEven;
pub const Trunc = zmath.Trunc;
pub const Max = zmath.Max;
pub const Min = zmath.Min;
pub const Sqrt = zmath.Sqrt;
pub const Pow = zmath.Pow;
pub const Pow10 = zmath.Pow10;
pub const Sin = zmath.Sin;
pub const Cos = zmath.Cos;
pub const Tan = zmath.Tan;
pub const Exp = zmath.Exp;
pub const Log = zmath.Log;
pub const Log10 = zmath.Log10;
pub const Log2 = zmath.Log2;
pub const NaN = zmath.NaN;
pub const Inf = zmath.Inf;
pub const IsInf = zmath.IsInf;
pub const IsNaN = zmath.IsNaN;

// Re-export types/functions/constants from zio
pub const Reader = zio.Reader;
pub const Writer = zio.Writer;
pub const Closer = zio.Closer;
pub const Seeker = zio.Seeker;
pub const SeekStart = zio.SeekStart;
pub const SeekCurrent = zio.SeekCurrent;
pub const SeekEnd = zio.SeekEnd;
pub const EOF = zio.EOF;
pub const ErrUnexpectedEOF = zio.ErrUnexpectedEOF;
pub const ErrShortWrite = zio.ErrShortWrite;
pub const copy = zio.copy;
pub const copyBuffer = zio.copyBuffer;
pub const readAll = zio.readAll;
pub const writeString = zio.writeString;
pub const LimitReader = zio.LimitReader;
pub const TeeReader = zio.TeeReader;
pub const multiWriter = zio.multiWriter;
pub const BufferedReader = zio.BufferedReader;
pub const BufferedWriter = zio.BufferedWriter;
pub const newReader = zio.newReader;
pub const newWriter = zio.newWriter;
pub const readBytes = zio.readBytes;
pub const readString = zio.readString;
pub const flush = zio.flush;

// Re-export types/functions/constants from zreflect
pub const Type = zreflect.Type;
pub const TypeOf = zreflect.TypeOf;
pub const Kind = zreflect.Kind;
pub const TypeKind = zreflect.TypeKind;
pub const NumField = zreflect.NumField;
pub const StructField = zreflect.StructField;
pub const Field = zreflect.Field;
pub const GetField = zreflect.GetField;
pub const SetField = zreflect.SetField;

// Re-export types/functions/constants from ztime
pub const Duration = ztime.Duration;
pub const Nanosecond = ztime.Nanosecond;
pub const Microsecond = ztime.Microsecond;
pub const Millisecond = ztime.Millisecond;
pub const Second = ztime.Second;
pub const Minute = ztime.Minute;
pub const Hour = ztime.Hour;
pub const Time = ztime.Time;
pub const Now = ztime.Now;
// Export renamed static constructors
pub const FromUnix = ztime.Time.FromUnix;
pub const FromUnixNano = ztime.Time.FromUnixNano;
pub const Sleep = ztime.Sleep;
pub const Parse = ztime.Parse;
pub const LayoutIso = ztime.LayoutIso;
pub const LayoutRfc3339 = ztime.LayoutRfc3339;
pub const LayoutDateOnly = ztime.LayoutDateOnly;
pub const LayoutTimeOnly = ztime.LayoutTimeOnly;

// Re-export functions from zasm
pub const cpuid = zasm.cpuid;
pub const addU64Asm = zasm.addU64; // Renamed slightly to avoid potential future conflicts
pub const subU64Asm = zasm.subU64;
pub const atomicAddU64Asm = zasm.atomicAddU64;
pub const syscall3Asm = zasm.syscall3; // Highly non-portable

// Keep the original add function for demonstration/completeness
pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

// You might want to add a test block here that specifically uses the imported functions
// to ensure the export works, though the tests in strings.zig cover functionality.
test "exported string functions" {
    const allocator = testing.allocator;
    const reversed = try reverse(allocator, "test");
    defer allocator.free(reversed);
    try testing.expectEqualStrings("tset", reversed);
    try testing.expect(startsWith("abc", "a"));
}

// Add a test block for exported net/http functions (optional, basic check)
test "exported net/http functions" {
    _ = znet.parseIP; // Check if net symbols are accessible
    _ = zhttp.Client; // Check if http symbols are accessible
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zmt functions (optional, basic check)
test "exported zmt functions" {
    _ = zmt.Printf; // Check if zmt symbols are accessible
    _ = zmt.Sprintf;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported slices functions (optional, basic check)
test "exported slices functions" {
    _ = zslices.Contains; // Check if slices symbols are accessible
    _ = zslices.Index;
    _ = zslices.Sort;
    _ = zslices.Reverse;
    _ = zslices.Clone;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported ws functions (optional, basic check)
test "exported ws functions" {
    _ = zws.Upgrader; // Check if ws symbols are accessible
    _ = zws.Conn;
    _ = zws.OpcodeText;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zmem functions (optional, basic check)
test "exported zmem functions" {
    _ = zmem.equalFold; // Check if zmem symbols are accessible
    _ = zmem.lastIndex;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zallocator functions (optional, basic check)
test "exported zallocator functions" {
    _ = zallocator.CountingAllocator; // Check if zallocator symbols are accessible
    _ = zallocator.LimitedAllocator;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zsort functions (optional, basic check)
test "exported zsort functions" {
    _ = zsort.isSorted; // Check if zsort symbols are accessible
    _ = zsort.Search;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zbytes functions (optional, basic check)
test "exported zbytes functions" {
    _ = zbytes.Compare; // Check if zbytes symbols are accessible
    _ = zbytes.Contains;
    _ = zbytes.Count;
    _ = zbytes.Fields;
    _ = zbytes.Join;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zcmp functions (optional, basic check)
test "exported zcmp functions" {
    _ = zcmp.Compare; // Check if zcmp symbols are accessible
    _ = zcmp.Less;
    // Check exported names
    _ = CmpCompare;
    _ = CmpLess;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported ziter functions (optional, basic check)
test "exported ziter functions" {
    _ = ziter.Seq; // Check if ziter symbols are accessible
    _ = ziter.RangeIterator;
    // Check exported names
    _ = Seq;
    _ = RangeIterator;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zasync functions (optional, basic check)
test "exported zasync functions" {
    _ = zasync.Mutex; // Check if zasync symbols are accessible
    _ = zasync.RWMutex;
    _ = zasync.Cond;
    _ = zasync.WaitGroup;
    _ = zasync.Once;
    _ = zasync.AddU64;
    _ = zasync.LoadPointer;
    // Check exported names
    _ = Mutex;
    _ = WaitGroup;
    _ = AddI64;
    _ = LoadBool;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zmath functions (optional, basic check)
test "exported zmath functions" {
    _ = zmath.Pi; // Check if zmath symbols are accessible
    _ = zmath.Abs;
    _ = zmath.Sqrt;
    _ = zmath.Sin;
    _ = zmath.IsNaN;
    // Check exported names
    _ = Pi;
    _ = Abs;
    _ = Sqrt;
    _ = Sin;
    _ = IsNaN;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zio functions (optional, basic check)
test "exported zio functions" {
    _ = zio.Reader; // Check if zio symbols are accessible
    _ = zio.Writer;
    _ = zio.Seeker;
    _ = zio.copy;
    _ = zio.LimitReader;
    _ = zio.TeeReader;
    _ = zio.newReader;
    _ = zio.readString;
    _ = zio.EOF;
    // Check exported names
    _ = Reader;
    _ = Writer;
    _ = copy;
    _ = LimitReader;
    _ = newReader;
    _ = readString;
    _ = EOF;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zreflect functions (optional, basic check)
test "exported zreflect functions" {
    _ = zreflect.TypeOf; // Check if zreflect symbols are accessible
    _ = zreflect.TypeKind;
    _ = zreflect.NumField;
    _ = zreflect.GetField;
    _ = zreflect.SetField;
    // Check exported names
    _ = TypeOf;
    _ = TypeKind;
    _ = NumField;
    _ = GetField;
    _ = SetField;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported ztime functions (optional, basic check)
test "exported ztime functions" {
    _ = ztime.Duration; // Check if ztime symbols are accessible
    _ = ztime.Time;
    _ = ztime.Now;
    _ = ztime.Time.FromUnix; // Check renamed static function
    _ = ztime.Time.FromUnixNano; // Check renamed static function
    _ = ztime.Sleep;
    _ = ztime.Parse;
    _ = ztime.LayoutIso;
    // Check exported names
    _ = Duration;
    _ = Time;
    _ = Now;
    _ = FromUnix; // Check exported renamed static function
    _ = FromUnixNano; // Check exported renamed static function
    _ = Sleep;
    _ = Parse;
    _ = LayoutIso;
    try testing.expect(true); // Simple pass if symbols resolve
}

// Add a test block for exported zasm functions (optional, basic check)
test "exported zasm functions" {
    _ = zasm.cpuid; // Check if zasm symbols are accessible
    _ = zasm.addU64;
    _ = zasm.subU64;
    _ = zasm.atomicAddU64;
    _ = zasm.syscall3;
    // Check exported names
    _ = cpuid;
    _ = addU64Asm;
    _ = subU64Asm;
    _ = atomicAddU64Asm;
    _ = syscall3Asm;
    try testing.expect(true); // Simple pass if symbols resolve
}
