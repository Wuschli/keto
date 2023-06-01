const c = @import("./chunk.zig");
const Chunk = c.Chunk(u8);
const OpCode = c.OpCode;
const std = @import("std");
const Writer = std.fs.File.Writer;
const Value = @import("./value.zig").Value;

pub fn disassembleChunk(self: *Chunk, name: []const u8, writer: Writer) !void {
    try writer.print("=== {s} ===\n", .{name});
    var offset: usize = 0;
    while (offset < self.count()) {
        offset = try disassembleInstruction(self, offset, writer);
    }
}

pub fn disassembleInstruction(self: *Chunk, offset: usize, writer: Writer) !usize {
    try writer.print("[{x:0>4}] ", .{offset});
    const instruction = self.code.items[offset];
    switch (@intToEnum(OpCode, instruction)) {
        .op_constant => return constantInstruction(.op_constant, self, offset, writer),
        .op_return => return simpleInstruction(.op_return, offset, writer),
        else => {
            try writer.print("Unknown opcode {x:0>2}\n", .{instruction});
            return offset + 1;
        },
    }
    return offset + 1;
}

pub fn simpleInstruction(opcode: OpCode, offset: usize, writer: Writer) !usize {
    try writer.print("{s}\n", .{@tagName(opcode)});
    return offset + 1;
}

pub fn constantInstruction(opcode: OpCode, chunk: *Chunk, offset: usize, writer: Writer) !usize {
    const constant = chunk.code.items[offset + 1];
    try writer.print("{s} [{d:0>4}] ", .{ @tagName(opcode), constant });

    try printValue(chunk.constants.items[constant], writer);
    try writer.print("'\n", .{});
    return offset + 2;
}

pub fn printValue(value: Value, writer: Writer) !void {
    try writer.print("{d}", .{value});
}