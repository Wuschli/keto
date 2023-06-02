const std = @import("std");
const c = @import("./chunk.zig");
const Chunk = c.Chunk(u8);
const debug = @import("./debug.zig");
const v = @import("./vm.zig");
const VM = v.VM;
const build_options = @import("build_options");
const Allocator = std.mem.Allocator;
const InterpretResult = v.InterpretResult;

pub fn main() !u8 {
    const argv = std.os.argv;
    const a = std.heap.c_allocator;
    var vm = try VM.init(a);
    defer vm.free();
    if (argv.len == 1) {
        try repl();
    } else if (argv.len == 2) {
        const path = argv.ptr[1][0..std.mem.len(argv.ptr[1])];
        const result = try runFile(&vm, path, a);

        if (result == .compile_error)
            return 65;
        if (result == .runtime_error)
            return 70;
    } else {
        return 64;
    }
    return 0;
    // var chunk = try Chunk.init(a);
    // defer chunk.free();
    // const constant = try chunk.addConstant(3.1415);
    // try chunk.writeOpCode(.constant, 123);
    // try chunk.writeOffset(constant, 123);
    // try chunk.writeOpCode(.negate, 123);
    // try chunk.writeOpCode(.constant, 123);
    // try chunk.writeOffset(constant, 123);
    // try chunk.writeOpCode(.subtract, 123);
    // try chunk.writeOpCode(.ret, 123);
    // if (build_options.trace)
    //     try debug.disassembleChunk(&chunk, "test", stdout);
    // const result = try vm.interpret(&chunk);
    // try stdout.print("{}\n", .{result});
}

fn repl() !void {}

fn runFile(vm: *VM, path: []const u8, a: Allocator) !InterpretResult {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    var buffer = try a.alloc(u8, file_size);
    defer a.free(buffer);
    for (buffer) |*value| {
        value.* = 0x00;
    }
    const bytes_read = try file.read(buffer);
    const source = buffer[0..bytes_read];

    // if (build_options.trace) {
    //     try writer.writeAll(source);
    //     try keto.log.info("\n", .{});
    // }

    const result = try vm.interpret(source, a);
    return result;
}
