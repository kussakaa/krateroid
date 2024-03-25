const Block = @import("Block.zig");
const Self = @This();

pub const w = 32;
pub const v = w * w * w;
pub const Pos = @Vector(3, u32);
blocks: [v]Block,

pub inline fn getBlock(self: Self, pos: Block.Pos) Block {
    return self.blocks[@intCast(blockPosToBlockIndex(pos))];
}

pub inline fn setBlock(self: *Self, pos: Block.Pos, block: Block) void {
    self.blocks[@intCast(blockPosToBlockIndex(pos))] = block;
}

pub inline fn blockPosToBlockIndex(pos: Block.Pos) u32 {
    return pos[0] + pos[1] * w + pos[2] * w * w;
}
