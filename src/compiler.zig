const c = @import("./chunk.zig");
const Line = c.Line;
const Chunk = c.Chunk(u8);
const sc = @import("./scanner.zig");
const Scanner = sc.Scanner;
const Token = sc.Token;
const p = @import("./parser.zig");
const Parser = p.Parser;
const std = @import("std");
const keto = @import("./keto.zig");
const Allocator = std.mem.Allocator;

pub fn compile(source: []const u8, chunk: *Chunk, a: Allocator) !bool {
    var scanner = try Scanner.init(source);
    var parser = Parser.init(&scanner, chunk, a);
    parser.advance();
    try parser.expression();
    parser.consume(.EOF, "Expect end of expression");
    try endCompiler(&parser);
    return !parser.hadError;
    // var line: Line = 0;
    // while (true) {
    //     const token = scanner.scanToken();

    //     if (token.line != line) {
    //         keto.log.info("{d:0>4} ", .{token.line});
    //         line = token.line;
    //     } else {
    //         keto.log.info("   | ", .{});
    //     }
    //     keto.log.info("{s} {s} \n", .{ @tagName(token.type), token.start });
    //     if (token.type == .EOF)
    //         break;
    // }
}

fn endCompiler(parser: *Parser) !void {
    try parser.emitReturn();
}
