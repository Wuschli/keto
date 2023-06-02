const std = @import("std");

pub fn info(comptime fmt: []const u8, args: anytype) void {
    std.io.getStdOut().writer().print(fmt, args) catch {};
}

pub fn err(comptime fmt: []const u8, args: anytype) void {
    std.io.getStdErr().writer().print(fmt, args) catch {};
}
