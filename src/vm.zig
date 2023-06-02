const c = @import("./chunk.zig");
const Chunk = c.Chunk(u8);
const OpCode = c.OpCode;
const v = @import("./value.zig");
const Value = v.Value;
const Debug = @import("./debug.zig");
const std = @import("std");
const build_options = @import("build_options");
const Allocator = std.mem.Allocator;
const compiler = @import("./compiler.zig");
const keto = @import("./keto.zig");

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

    pub fn init(a: Allocator) !Self {
        var vm = Self{
            .a = a,
            .chunk = null,
            .ip = null,
            .stack = try a.alloc(Value, build_options.stackSize),
            .stackTop = undefined,
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

    pub fn interpret(self: *Self, source: []const u8, a: Allocator) !InterpretResult {
        var chunk = try Chunk.init(a);
        defer chunk.free();

        if (!try compiler.compile(source, &chunk, a)) {
            return .compile_error;
        }

        self.chunk = &chunk;
        if (self.chunk.?.code.items.len == 0)
            return .compile_error;
        self.ip = self.chunk.?.code.items.ptr;
        return self.run();
    }

    fn run(self: *Self) InterpretResult {
        while (true) {
            if (build_options.trace) {
                keto.log.info("\n", .{});
                Debug.printStack(self);
                _ = Debug.disassembleInstruction(self.chunk.?, @ptrToInt(self.ip.?) - @ptrToInt(self.chunk.?.code.items.ptr));
            }
            const instruction = self.readByte();
            switch (@intToEnum(OpCode, instruction)) {
                .CONSTANT => {
                    const value = self.readConstant();
                    self.push(value);
                },
                .NEGATE => self.push(-self.pop()),
                .ADD => self.binaryOp(add),
                .SUBTRACT => self.binaryOp(sub),
                .MULTIPLY => self.binaryOp(mul),
                .DIVIDE => self.binaryOp(div),
                .RETURN => {
                    Debug.printValue(self.pop());
                    keto.log.info("\n", .{});
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

    fn binaryOp(self: *Self, comptime op: fn (Value, Value) Value) void {
        const b = self.pop();
        const a = self.pop();
        self.push(op(a, b));
    }

    fn add(a: Value, b: Value) Value {
        return a + b;
    }

    fn sub(a: Value, b: Value) Value {
        return a - b;
    }

    fn mul(a: Value, b: Value) Value {
        return a * b;
    }

    fn div(a: Value, b: Value) Value {
        return a / b;
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
    // keto.log.warn("0x{x}, 0x{x}", .{ stackAddr, stackTopAddr });
    // keto.log.warn("{d}, {d}", .{ stackAddr, stackTopAddr });
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
    // keto.log.warn("{any}, {d}\n", .{ vm.stack, vm.stackTop[0] });
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
    // keto.log.warn("{any}, {d}\n", .{ vm.stack, vm.stackTop[0] });
    try std.testing.expect(vm.stack[0] == 3.1415);
    try std.testing.expect(vm.stackTop[0] == 0);
    const pi = vm.pop();
    try std.testing.expect(pi == 3.1415);
    try std.testing.expect(vm.stackTop[0] == pi);
}
