const std = @import("std");
const c = @import("./chunk.zig");
const Chunk = c.Chunk(u8);
const debug = @import("./debug.zig");
const VM = @import("./vm.zig").VM;
const build_options = @import("build_options");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const a = std.heap.c_allocator;
    var vm = try VM.init(a, stdout);
    defer vm.free();
    var chunk = try Chunk.init(a);
    defer chunk.free();
    const constant = try chunk.addConstant(3.1415);
    try chunk.writeOpCode(.op_constant, 123);
    try chunk.writeOffset(constant, 123);
    try chunk.writeOpCode(.op_negate, 123);
    try chunk.writeOpCode(.op_constant, 123);
    try chunk.writeOffset(constant, 123);
    try chunk.writeOpCode(.op_subtract, 123);
    try chunk.writeOpCode(.op_return, 123);
    if (build_options.trace)
        try debug.disassembleChunk(&chunk, "test", stdout);
    const result = try vm.interpret(&chunk);
    try stdout.print("{}\n", .{result});
}
