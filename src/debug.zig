const c = @import("./chunk.zig");
const Chunk = c.Chunk(u8);
const OpCode = c.OpCode;
const std = @import("std");
const Value = @import("./value.zig").Value;
const VM = @import("./vm.zig").VM;
const keto = @import("./keto.zig");

pub fn disassembleChunk(self: *Chunk, name: []const u8) void {
    keto.log.info("=== {s} ===\n", .{name});
    var offset: usize = 0;
    while (offset < self.count()) {
        offset = disassembleInstruction(
            self,
            offset,
        );
    }
}

pub fn disassembleInstruction(self: *Chunk, offset: usize) usize {
    keto.log.info("[{x:0>4}] ", .{offset});
    if (offset > 0 and self.lines.items[offset] == self.lines.items[offset - 1]) {
        keto.log.info("    | ", .{});
    } else if (self.lines.items.len > 0) {
        keto.log.info("{d: >5} ", .{self.lines.items[offset]});
    } else {
        keto.log.info("????? ", .{});
    }
    const instruction = self.code.items[offset];
    switch (@intToEnum(OpCode, instruction)) {
        .CONSTANT => return constantInstruction(.CONSTANT, self, offset),
        .NEGATE => return simpleInstruction(.NEGATE, offset),
        .ADD => return simpleInstruction(.ADD, offset),
        .SUBTRACT => return simpleInstruction(.SUBTRACT, offset),
        .MULTIPLY => return simpleInstruction(.MULTIPLY, offset),
        .DIVIDE => return simpleInstruction(.DIVIDE, offset),
        .RETURN => return simpleInstruction(.RETURN, offset),
        _ => {
            keto.log.info("Unknown opcode {x:0>2}\n", .{instruction});
            return offset + 1;
        },
    }
    return offset + 1;
}

pub fn simpleInstruction(opcode: OpCode, offset: usize) usize {
    keto.log.info("{s}\n", .{@tagName(opcode)});
    return offset + 1;
}

pub fn constantInstruction(opcode: OpCode, chunk: *Chunk, offset: usize) usize {
    const constant = chunk.code.items[offset + 1];
    keto.log.info("{s}\t{d: >4}: ", .{ @tagName(opcode), constant });

    printValue(chunk.constants.items[constant]);
    keto.log.info("\n", .{});
    return offset + 2;
}

pub fn printValue(value: Value) void {
    keto.log.info("'{}'", .{value});
}

pub fn printStack(vm: *VM) void {
    keto.log.info("             Stack: ", .{});
    for (vm.stack) |*value| {
        if (@ptrToInt(value) >= @ptrToInt(vm.stackTop.ptr))
            break;
        keto.log.info("[ ", .{});
        printValue(value.*);
        keto.log.info(" ]", .{});
    }
    keto.log.info("\n", .{});
}
