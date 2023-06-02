const c = @import("./chunk.zig");
const Chunk = c.Chunk(u8);
const OpCode = c.OpCode;
const std = @import("std");
const Writer = std.fs.File.Writer;
const Value = @import("./value.zig").Value;
const VM = @import("./vm.zig").VM;

pub fn disassembleChunk(self: *Chunk, name: []const u8, writer: Writer) !void {
    try writer.print("=== {s} ===\n", .{name});
    var offset: usize = 0;
    while (offset < self.count()) {
        offset = try disassembleInstruction(self, offset, writer);
    }
}

pub fn disassembleInstruction(self: *Chunk, offset: usize, writer: Writer) !usize {
    try writer.print("[{x:0>4}] ", .{offset});
    if (offset > 0 and self.lines.items[offset] == self.lines.items[offset - 1]) {
        try writer.print("    | ", .{});
    } else {
        try writer.print("{d: >5} ", .{self.lines.items[offset]});
    }
    const instruction = self.code.items[offset];
    switch (@intToEnum(OpCode, instruction)) {
        .op_constant => return constantInstruction(.op_constant, self, offset, writer),
        .op_negate => return simpleInstruction(.op_negate, offset, writer),
        .op_add => return simpleInstruction(.op_add, offset, writer),
        .op_subtract => return simpleInstruction(.op_subtract, offset, writer),
        .op_multiply => return simpleInstruction(.op_multiply, offset, writer),
        .op_divide => return simpleInstruction(.op_divide, offset, writer),
        .op_return => return simpleInstruction(.op_return, offset, writer),
        _ => {
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
    try writer.print("{s}\t{d: >4}: ", .{ @tagName(opcode), constant });

    try printValue(chunk.constants.items[constant], writer);
    try writer.print("\n", .{});
    return offset + 2;
}

pub fn printValue(value: Value, writer: Writer) !void {
    try writer.print("'{}'", .{value});
}

pub fn printStack(vm: *VM) !void {
    try vm.writer.print("             Stack: ", .{});
    for (vm.stack) |*value| {
        if (@ptrToInt(value) >= @ptrToInt(vm.stackTop.ptr))
            break;
        try vm.writer.print("[ ", .{});
        try printValue(value.*, vm.writer);
        try vm.writer.print(" ]", .{});
    }
    try vm.writer.print("\n", .{});
}
