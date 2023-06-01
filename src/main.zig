const std = @import("std");
const c = @import("./chunk.zig");
const Chunk = c.Chunk(u8);
const debug = @import("./debug.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const a = std.heap.c_allocator;
    var chunk = try Chunk.init(a);
    const constant = try chunk.addConstant(3.1415);
    try chunk.writeOpCode(.op_constant);
    try chunk.writeOffset(constant);
    try chunk.writeOpCode(.op_return);
    try debug.disassembleChunk(&chunk, "test", stdout);
}
