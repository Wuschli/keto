const c = @import("./chunk.zig");
const Line = c.Line;
const sc = @import("./scanner.zig");
const Scanner = sc.Scanner;
const std = @import("std");
const Writer = std.fs.File.Writer;

pub fn compile(source: []const u8, writer: Writer) !void {
    var scanner = try Scanner.init(source);
    var line: Line = 0;
    while (true) {
        const token = scanner.scanToken();

        if (token.line != line) {
            try writer.print("{d:0>4} ", .{token.line});
            line = token.line;
        } else {
            try writer.print("   | ", .{});
        }
        try writer.print("{s} {s} \n", .{ @tagName(token.type), token.start });
        if (token.type == .EOF)
            break;
    }
}
