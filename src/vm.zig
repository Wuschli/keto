const c = @import("./chunk.zig");
const Chunk = c.Chunk(u8);
const OpCode = c.OpCode;
const v = @import("./value.zig");
const Value = v.Value;
const Debug = @import("./debug.zig");
const std = @import("std");
const Writer = std.fs.File.Writer;
const build_options = @import("build_options");
const Allocator = std.mem.Allocator;

pub const InterpretResult = enum {
    ok,
    compile_error,
    runtime_error,
};

pub const VM = struct {
    const Self = @This();
    a: Allocator,
    chunk: ?*Chunk,
    ip: ?[*]u8,
    stack: []Value,
    stackTop: []Value,
    writer: Writer,

    pub fn init(a: Allocator, writer: Writer) !Self {
        var vm = Self{
            .a = a,
            .chunk = null,
            .ip = null,
            .stack = try a.alloc(Value, build_options.stackSize),
            .stackTop = undefined,
            .writer = writer,
        };
        vm.resetStack();
        return vm;
    }

    pub fn free(self: *Self) void {
        self.a.free(self.stack);
    }

    fn resetStack(self: *Self) void {
        for (self.stack) |*value|
            value.* = 0; // initialize stack with zeros
        self.stackTop = self.stack[0..];
    }

    pub fn interpret(self: *Self, chunk: *Chunk) !InterpretResult {
        self.chunk = chunk;
        self.ip = self.chunk.?.code.items.ptr;
        return try self.run();
    }

    fn run(self: *Self) !InterpretResult {
        while (true) {
            if (build_options.trace) {
                try self.writer.print("\n", .{});
                try Debug.printStack(self);
                _ = try Debug.disassembleInstruction(self.chunk.?, @ptrToInt(self.ip.?) - @ptrToInt(self.chunk.?.code.items.ptr), self.writer);
            }
            const instruction = self.readByte();
            switch (@intToEnum(OpCode, instruction)) {
                .op_constant => {
                    const value = self.readConstant();
                    self.push(value);
                },
                .op_return => {
                    try Debug.printValue(self.pop(), self.writer);
                    try self.writer.print("\n", .{});
                    return .ok;
                },
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

    fn push(self: *Self, value: Value) void {
        self.stackTop[0] = value;
        self.stackTop.ptr += 1;
        self.stackTop.len -= 1;
    }

    fn pop(self: *Self) Value {
        self.stackTop.ptr -= 1;
        self.stackTop.len += 1;
        return self.stackTop[0];
    }
};
test "init stack" {
    const a = std.testing.allocator;
    const stdout = std.io.getStdOut().writer();
    var chunk = try Chunk.init(a);
    defer chunk.free();
    var vm = try VM.init(a, stdout);
    defer vm.free();
    const stackAddr = @ptrToInt(vm.stack.ptr);
    const stackTopAddr = @ptrToInt(vm.stackTop.ptr);
    // std.log.warn("0x{x}, 0x{x}", .{ stackAddr, stackTopAddr });
    // std.log.warn("{d}, {d}", .{ stackAddr, stackTopAddr });
    try std.testing.expect(stackAddr == stackTopAddr);
}

test "push" {
    const a = std.testing.allocator;
    const stdout = std.io.getStdOut().writer();
    var chunk = try Chunk.init(a);
    defer chunk.free();
    var vm = try VM.init(a, stdout);
    defer vm.free();
    vm.push(3.1415);
    // std.log.warn("{any}, {d}\n", .{ vm.stack, vm.stackTop[0] });
    try std.testing.expect(vm.stack[0] == 3.1415);
    try std.testing.expect(vm.stackTop[0] == 0);
}

test "pop" {
    const a = std.testing.allocator;
    const stdout = std.io.getStdOut().writer();
    var chunk = try Chunk.init(a);
    defer chunk.free();
    var vm = try VM.init(a, stdout);
    defer vm.free();
    vm.push(3.1415);
    // std.log.warn("{any}, {d}\n", .{ vm.stack, vm.stackTop[0] });
    try std.testing.expect(vm.stack[0] == 3.1415);
    try std.testing.expect(vm.stackTop[0] == 0);
    const pi = vm.pop();
    try std.testing.expect(pi == 3.1415);
    try std.testing.expect(vm.stackTop[0] == pi);
}
