pub const Chunk = @import("./chunk.zig").Chunk;
pub const OpCode = @import("./chunk.zig").OpCode;

test {
    @import("std").testing.refAllDeclsRecursive(@This());
}
