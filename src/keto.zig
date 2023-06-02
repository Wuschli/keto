pub const Chunk = @import("./chunk.zig").Chunk;
pub const OpCode = @import("./chunk.zig").OpCode;
pub const VM = @import("./vm.zig").VM;
pub const log = @import("./log.zig");

test {
    @import("std").testing.refAllDeclsRecursive(@This());
}
