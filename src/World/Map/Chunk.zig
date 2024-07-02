tiles: [volume]Tile,

pub const size = Size{ 32, 32 };
pub const volume = size[0] * size[1];

pub inline fn getTile(chunk: *Chunk, pos: Pos) Tile {
    return chunk.tiles[@intCast(pos[0] + pos[1] * size[0])];
}

pub inline fn setTile(chunk: *Chunk, pos: Pos, tile: Tile) void {
    chunk.tiles[@intCast(pos[0] + pos[1] * size[0])] = tile;
}

const Chunk = @This();
const Size = @Vector(2, i32);
const Seed = i32;
const Pos = @Vector(2, i32);
const Tile = @import("Tile.zig");
