const std = @import("std");
const Allocator = std.mem.Allocator;

const ChunkError = error{
    ChunkFreed,
};

pub const OpCode = enum(u8) {
    op_return,
    _,
};

pub fn Chunk(comptime T: type) type {
    return struct {
        const Self = @This();

        code: std.ArrayList(T),
        a: Allocator,
        freed: bool,

        pub fn init(a: Allocator) !Self {
            var code = std.ArrayList(T).init(a);
            return Self{
                .code = code,
                .a = a,
                .freed = false,
            };
        }

        pub fn free(self: *Self) void {
            self.code.deinit();
            self.freed = true;
        }

        pub fn count(self: *Self) usize {
            return self.code.items.len;
        }

        pub fn writeOpCode(self: *Self, opCode: OpCode) !void {
            try writeByte(self, comptime @enumToInt(opCode));
        }

        pub fn writeByte(self: *Self, byte: T) !void {
            if (self.freed)
                return ChunkError.ChunkFreed;
            try self.code.append(byte);
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
    try chunk.writeByte(0xFF);
    try std.testing.expect(chunk.code.items.len == 1);
}

test "write OpCode" {
    const a = std.testing.allocator;
    var chunk = try Chunk(u8).init(a);
    defer chunk.free();
    try chunk.writeOpCode(.op_return);
    try std.testing.expect(chunk.code.items.len == 1);
}

test "free Chunk" {
    const a = std.testing.allocator;
    var chunk = try Chunk(u8).init(a);
    try chunk.writeOpCode(.op_return);
    try std.testing.expect(chunk.code.items.len == 1);
    chunk.free();
    try std.testing.expectError(ChunkError.ChunkFreed, chunk.writeOpCode(.op_return));
}
