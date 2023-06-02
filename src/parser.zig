const sc = @import("./scanner.zig");
const Scanner = sc.Scanner;
const Token = sc.Token;
const TokenType = sc.TokenType;
const c = @import("./chunk.zig");
const Chunk = c.Chunk(u8);
const OpCode = c.OpCode;
const std = @import("std");
const keto = @import("./keto.zig");
const Value = @import("./value.zig").Value;
const Allocator = std.mem.Allocator;

const Precedence = enum(u8) {
    NONE,
    ASSIGNMENT, // =
    OR, // or
    AND, // and
    EQUALITY, // == !=
    COMPARISON, // < > <= >=
    TERM, // + -
    FACTOR, // * /
    UNARY, // ! -
    CALL, // . ()
    PRIMARY,
};

const ParseFn = ?*const fn (*Parser) anyerror!void;

const ParseRule = struct {
    const Self = @This();

    prefix: ParseFn,
    infix: ParseFn,
    precedence: Precedence,
};

pub const Parser = struct {
    const Self = @This();

    current: Token,
    previous: Token,
    hadError: bool = false,
    panicMode: bool = false,
    compilingChunk: *Chunk,
    scanner: *Scanner,

    pub fn init(scanner: *Scanner, chunk: *Chunk, a: Allocator) Parser {
        _ = a;
        var result = Self{
            .current = undefined,
            .previous = undefined,
            .hadError = false,
            .panicMode = false,
            .compilingChunk = chunk,
            .scanner = scanner,
        };
        return result;
    }

    pub fn advance(self: *Self) void {
        self.previous = self.current;

        while (true) {
            self.current = self.scanner.scanToken();
            if (self.current.type != .ERROR) break;

            self.errorAtCurrent(self.current.start);
        }
    }

    pub fn expression(self: *Self) !void {
        try self.parsePrecedence(.ASSIGNMENT);
    }

    pub fn consume(self: *Self, tokenType: TokenType, message: []const u8) void {
        if (self.current.type == tokenType) {
            self.advance();
            return;
        }

        self.errorAtCurrent(message);
    }

    fn currentChunk(self: *Self) *Chunk {
        return self.compilingChunk;
    }

    fn errorAtCurrent(self: *Self, message: []const u8) void {
        self.errorAt(self.current, message);
    }

    fn err(self: *Self, message: []const u8) void {
        self.errorAt(self.previous, message);
    }

    fn errorAt(self: *Self, token: Token, message: []const u8) void {
        if (self.panicMode) return;
        self.panicMode = true;
        keto.log.err("[line {d: >4}] Error", .{token.line});
        if (token.type == .EOF) {
            keto.log.err(" at end", .{});
        } else if (token.type == .ERROR) {
            //nothing
        } else {
            keto.log.err(" at '{s}", .{token.start});
        }
        keto.log.err(": {s}\n", .{message});
        self.hadError = true;
    }

    fn emitByte(self: *Self, byte: u8) !void {
        try self.currentChunk().*.writeByte(byte, self.previous.line);
    }

    fn emitOpCode(self: *Self, opCode: OpCode) !void {
        try self.emitByte(@enumToInt(opCode));
    }

    fn emitBytes(self: *Self, opCode: OpCode, byte: u8) !void {
        try self.emitOpCode(opCode);
        try self.emitByte(byte);
    }

    pub fn emitReturn(self: *Self) !void {
        try self.emitOpCode(.RETURN);
    }

    fn emitConstant(self: *Self, value: Value) !void {
        try self.emitBytes(.CONSTANT, self.makeConstant(value));
    }

    fn makeConstant(self: *Self, value: Value) u8 {
        const constant = self.currentChunk().addConstant(value) catch unreachable;
        if (constant > std.math.maxInt(u8)) {
            self.err("Too many constants in one chunk.");
            return 0;
        }
        return @intCast(u8, constant);
    }

    fn grouping(self: *Self) !void {
        try self.expression();
        self.consume(.RIGHT_PAREN, "Expect ')' after expression.");
    }

    fn number(self: *Self) !void {
        const value = std.fmt.parseFloat(Value, self.previous.start) catch unreachable;
        try self.emitConstant(value);
    }

    fn unary(self: *Self) !void {
        const operatorType = self.previous.type;

        // compile the operand.
        try self.parsePrecedence(.UNARY);

        try switch (operatorType) {
            .MINUS => self.emitOpCode(.NEGATE),
            else => unreachable,
        };
    }

    fn binary(self: *Self) !void {
        const operatorType = self.previous.type;
        const rule = getRule(operatorType);
        try self.parsePrecedence(@intToEnum(Precedence, @enumToInt(rule.precedence) + 1));

        try switch (operatorType) {
            .PLUS => self.emitOpCode(.ADD),
            .MINUS => self.emitOpCode(.SUBTRACT),
            .STAR => self.emitOpCode(.MULTIPLY),
            .SLASH => self.emitOpCode(.DIVIDE),
            else => unreachable,
        };
    }

    fn parsePrecedence(self: *Self, precedence: Precedence) !void {
        self.advance();
        const prefixRule = getRule(self.previous.type).prefix;
        if (prefixRule == null) {
            self.err("Expect expression.");
            return;
        }

        try prefixRule.?(self);

        while (@enumToInt(precedence) <= @enumToInt(getRule(self.current.type).precedence)) {
            self.advance();
            const infixRule = getRule(self.previous.type).infix;
            try infixRule.?(self);
        }
    }

    fn getRule(tokenType: TokenType) ParseRule {
        return switch (tokenType) {
            .LEFT_PAREN => .{ .prefix = grouping, .infix = null, .precedence = .NONE },
            .RIGHT_PAREN => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .LEFT_BRACE => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .RIGHT_BRACE => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .COMMA => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .DOT => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .MINUS => .{ .prefix = unary, .infix = binary, .precedence = .TERM },
            .PLUS => .{ .prefix = null, .infix = binary, .precedence = .TERM },
            .SEMICOLON => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .SLASH => .{ .prefix = null, .infix = binary, .precedence = .FACTOR },
            .STAR => .{ .prefix = null, .infix = binary, .precedence = .FACTOR },
            .BANG => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .BANG_EQUAL => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .EQUAL => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .EQUAL_EQUAL => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .GREATER => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .GREATER_EQUAL => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .LESS => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .LESS_EQUAL => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .IDENTIFIER => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .STRING => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .NUMBER => .{ .prefix = number, .infix = null, .precedence = .NONE },
            .AND => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .CLASS => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .ELSE => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .FALSE => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .FOR => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .FUN => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .IF => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .NIL => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .OR => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .PRINT => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .RETURN => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .SUPER => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .THIS => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .TRUE => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .VAR => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .WHILE => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .ERROR => .{ .prefix = null, .infix = null, .precedence = .NONE },
            .EOF => .{ .prefix = null, .infix = null, .precedence = .NONE },
        };
    }
};
