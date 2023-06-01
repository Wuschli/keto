const c = @import("./chunk.zig");
const Chunk = c.Chunk(u8);
const OpCode = c.OpCode;
const v = @import("./value.zig");
const Value = v.Value;
const Debug = @import("./debug.zig");
const std = @import("std");
const Writer = std.fs.File.Writer;
const build_options = @import("build_options");

pub const InterpretResult = enum {
    ok,
    compile_error,
    runtime_error,
};

pub const VM = struct {
    const Self = @This();
    chunk: ?*Chunk,
    ip: ?[*]u8,
    writer: Writer,

    pub fn init(writer: Writer) Self {
        return Self{
            .chunk = null,
            .ip = null,
            .writer = writer,
        };
    }

    pub fn free(self: *Self) void {
        _ = self;
    }

    pub fn interpret(self: *Self, chunk: *Chunk) !InterpretResult {
        self.chunk = chunk;
        self.ip = self.chunk.?.code.items.ptr;
        return try self.run();
    }

    fn run(self: *Self) !InterpretResult {
        while (true) {
            if (build_options.trace) {
                _ = try Debug.disassembleInstruction(self.chunk.?, @ptrToInt(self.ip.?) - @ptrToInt(self.chunk.?.code.items.ptr), self.writer);
            }
            const instruction = self.readByte();
            switch (@intToEnum(OpCode, instruction)) {
                .op_constant => {
                    const value = self.readConstant();
                    try Debug.printValue(value, self.writer);
                    try self.writer.print("\n", .{});
                },
                .op_return => return .ok,
                _ => return .runtime_error,
            }
        }
        return .runtime_error;
    }

    fn readByte(self: *Self) u8 {
        const byte = self.ip.?[0];
        self.ip.? += 1;
        return byte;
    }

    fn readConstant(self: *Self) Value {
        return self.chunk.?.constants.items[self.readByte()];
    }
};
