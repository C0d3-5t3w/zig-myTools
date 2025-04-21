const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

/// Represents a type. Alias for Zig's `type`.
pub const Type = type;

/// Returns the compile-time type of `value`. Equivalent to `@TypeOf`.
pub fn TypeOf(value: anytype) Type {
    return @TypeOf(value);
}

/// Represents the kind of a type. Alias for `std.builtin.TypeInfo.Tag`.
pub const Kind = std.builtin.TypeInfo.Tag;

/// Returns the kind of the given type `T`.
pub fn TypeKind(comptime T: Type) Kind {
    return @typeInfo(T).tag;
}

/// Returns the number of fields in a struct type `T`.
/// Panics if `T` is not a struct.
pub fn NumField(comptime T: Type) usize {
    switch (@typeInfo(T)) {
        .Struct => |info| return info.fields.len,
        else => @compileError("NumField requires a struct type"),
    }
}

/// Represents information about a struct field. Alias for `std.builtin.TypeInfo.StructField`.
pub const StructField = std.builtin.TypeInfo.StructField;

/// Returns the i-th field of a struct type `T`.
/// Panics if `T` is not a struct or if `i` is out of bounds.
pub fn Field(comptime T: Type, i: usize) StructField {
    switch (@typeInfo(T)) {
        .Struct => |info| {
            if (i >= info.fields.len) @compileError("Field index out of bounds");
            return info.fields[i];
        },
        else => @compileError("Field requires a struct type"),
    }
}

/// Returns the value of the field named `field_name` in the struct `struct_val`.
/// This requires `field_name` to be known at compile time.
pub fn GetField(struct_val: anytype, comptime field_name: []const u8) @TypeOf(@field(struct_val, field_name)) {
    if (@typeInfo(@TypeOf(struct_val)) != .Struct) {
        @compileError("GetField requires a struct value");
    }
    // Ensure the field exists at compile time
    _ = comptime checkFieldExists(@TypeOf(struct_val), field_name);
    return @field(struct_val, field_name);
}

/// Sets the value of the field named `field_name` in the struct pointed to by `struct_ptr`.
/// Requires `field_name` to be known at compile time.
pub fn SetField(struct_ptr: anytype, comptime field_name: []const u8, value: anytype) void {
    const PtrT = @TypeOf(struct_ptr);
    if (@typeInfo(PtrT) != .Pointer) @compileError("SetField requires a pointer to a struct");
    const StructT = @typeInfo(PtrT).Pointer.child;
    if (@typeInfo(StructT) != .Struct) @compileError("SetField requires a pointer to a struct");

    // Ensure the field exists at compile time
    _ = comptime checkFieldExists(StructT, field_name);
    // Ensure the type matches
    comptime {
        const field_type = @TypeOf(@field(struct_ptr.*, field_name));
        const value_type = @TypeOf(value);
        if (field_type != value_type) {
            @compileError("Type mismatch: cannot set field '" ++ field_name ++ "' of type " ++ @typeName(field_type) ++ " with value of type " ++ @typeName(value_type));
        }
    }

    @field(struct_ptr.*, field_name) = value;
}

// Helper function for compile-time field existence check
fn checkFieldExists(comptime T: type, comptime name: []const u8) void {
    comptime {
        var found = false;
        for (@typeInfo(T).Struct.fields) |field| {
            if (std.mem.eql(u8, field.name, name)) {
                found = true;
                break;
            }
        }
        if (!found) {
            @compileError("Struct " ++ @typeName(T) ++ " has no field named '" ++ name ++ "'");
        }
    }
}

// --- Tests ---

const TestStruct = struct {
    a: i32,
    b: bool,
    c: []const u8,
};

test "Reflection helpers" {
    const val_i: i32 = 10;
    const val_struct = TestStruct{ .a = 42, .b = true, .c = "hello" };

    // TypeOf
    try testing.expect(TypeOf(val_i) == i32);
    try testing.expect(TypeOf(val_struct) == TestStruct);

    // TypeKind
    try testing.expect(TypeKind(i32) == .Int);
    try testing.expect(TypeKind(TestStruct) == .Struct);
    try testing.expect(TypeKind([]const u8) == .Slice);

    // NumField
    try testing.expectEqual(@as(usize, 3), NumField(TestStruct));

    // Field
    const field_a = Field(TestStruct, 0);
    const field_b = Field(TestStruct, 1);
    const field_c = Field(TestStruct, 2);
    try testing.expectEqualStrings("a", field_a.name);
    try testing.expect(field_a.type == i32);
    try testing.expectEqualStrings("b", field_b.name);
    try testing.expect(field_b.type == bool);
    try testing.expectEqualStrings("c", field_c.name);
    try testing.expect(field_c.type == []const u8);

    // GetField
    try testing.expectEqual(@as(i32, 42), GetField(val_struct, "a"));
    try testing.expectEqual(true, GetField(val_struct, "b"));
    try testing.expectEqualStrings("hello", GetField(val_struct, "c"));

    // SetField
    var mutable_struct = TestStruct{ .a = 1, .b = false, .c = "world" };
    SetField(&mutable_struct, "a", 99);
    SetField(&mutable_struct, "b", true);
    SetField(&mutable_struct, "c", "zig");

    try testing.expectEqual(@as(i32, 99), mutable_struct.a);
    try testing.expectEqual(true, mutable_struct.b);
    try testing.expectEqualStrings("zig", mutable_struct.c);
}

// Example of compile-time errors
// fn causeCompileErrors() void {
//     _ = NumField(i32); // Error: NumField requires a struct type
//     _ = Field(TestStruct, 3); // Error: Field index out of bounds
//     const s = TestStruct{ .a = 0, .b = false, .c = "" };
//     _ = GetField(s, "d"); // Error: Struct TestStruct has no field named 'd'
//     var ms = TestStruct{ .a = 0, .b = false, .c = "" };
//     SetField(&ms, "a", true); // Error: Type mismatch
// }
