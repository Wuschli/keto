const std = @import("std");
const v = @import("./value.zig");
const ValueArray = v.ValueArray;
const Value = v.Value;
pub const Line = u32;
const Allocator = std.mem.Allocator;

const ChunkError = error{
    ChunkFreed,
};

pub const OpCode = enum(u8) {
    CONSTANT,
    NEGATE,
    ADD,
    SUBTRACT,
    MULTIPLY,
    DIVIDE,
    RET,
    _,
};

pub fn Chunk(comptime T: type) type {
    return struct {
        const Self = @This();

        code: std.ArrayList(T),
        constants: ValueArray,
        lines: std.ArrayList(Line),
        a: Allocator,
        freed: bool,

        pub fn init(a: Allocator) !Self {
            var code = std.ArrayList(T).init(a);
            var constants = ValueArray.init(a);
            var lines = std.ArrayList(Line).init(a);
            return Self{
                .code = code,
                .constants = constants,
                .lines = lines,
                .a = a,
                .freed = false,
            };
        }

        pub fn free(self: *Self) void {
            self.code.deinit();
            self.constants.deinit();
            self.lines.deinit();
            self.freed = true;
        }

        pub fn count(self: *Self) usize {
            return self.code.items.len;
        }

        pub fn writeOpCode(self: *Self, opCode: OpCode, line: Line) !void {
            try writeByte(self, comptime @enumToInt(opCode), line);
        }

        pub fn writeOffset(self: *Self, offset: usize, line: Line) !void {
            try writeByte(self, comptime @truncate(u8, offset), line);
        }

        pub fn writeByte(self: *Self, byte: T, line: Line) !void {
            if (self.freed)
                return ChunkError.ChunkFreed;
            try self.code.append(byte);
            try self.lines.append(line);
        }

        pub fn addConstant(self: *Self, value: Value) !usize {
            if (self.freed)
                return ChunkError.ChunkFreed;
            try self.constants.append(value);
            return self.constants.items.len - 1;
        }
    };
}

test "create chunk" {
    const a = std.testing.allocator;
    var chunk = try Chunk(u8).init(a);
    defer chunk.free();
}

test "log chunk info" {
    const a = std.testing.allocator;
    var chunk = try Chunk(u8).init(a);
    defer chunk.free();
}

test "write Byte" {
    const a = std.testing.allocator;
    var chunk = try Chunk(u8).init(a);
    defer chunk.free();
    try chunk.writeByte(0xFF, 123);
    try std.testing.expect(chunk.code.items.len == 1);
}

test "write OpCode" {
    const a = std.testing.allocator;
    var chunk = try Chunk(u8).init(a);
    defer chunk.free();
    try chunk.writeOpCode(.ret, 123);
    try std.testing.expect(chunk.code.items.len == 1);
}

test "free Chunk" {
    const a = std.testing.allocator;
    var chunk = try Chunk(u8).init(a);
    try chunk.writeOpCode(.ret, 123);
    try std.testing.expect(chunk.code.items.len == 1);
    chunk.free();
    try std.testing.expectError(ChunkError.ChunkFreed, chunk.writeOpCode(.ret, 123));
}

test "add constant" {
    const a = std.testing.allocator;
    var chunk = try Chunk(u8).init(a);
    defer chunk.free();
    _ = try chunk.addConstant(3.1415);
    try std.testing.expect(chunk.constants.items.len == 1);
}
