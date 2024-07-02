chunks: []?*Chunk,
size: Size,
seed: Seed,
allocator: Allocator,

pub const Config = struct {
    size: Size = .{ 4, 4 },
    seed: Seed = 6969,
};

pub fn init(allocator: Allocator, config: Config) !Self {
    const size = config.size;
    const seed = config.seed;

    const chunks = try allocator.alloc(?*Chunk, @intCast(size[0] * size[1]));
    @memset(chunks[0..], null);

    //chunks[0] = try allocator.create(Chunk);
    //chunks[0] = Chunk.generate(seed);

    log.succes(.init, "WORLD Map", .{});

    return .{
        .chunks = chunks,
        .size = size,
        .seed = seed,
        .allocator = allocator,
    };
}

pub fn deinit(self: Self) void {
    self.allocator.free(self.chunks);
}

pub inline fn getChunk(self: *Self, pos: Pos) ?*Chunk {
    if (pos[0] < 0 or pos[1] < 0 or pos[0] >= self.size[0] or pos[1] >= self.size[1])
        return null;

    return self.chunks[@intCast(pos[0] + pos[1] * self.size[0])];
}

pub inline fn setChunk(self: *Self, pos: Pos, chunk: *Chunk) void {
    if (pos[0] < 0 or pos[1] < 0 or pos[0] >= self.size[0] or pos[1] >= self.size[1])
        return;

    self.chunks[@intCast(pos[0] + pos[1] * self.size[0])] = chunk;
}

pub inline fn getTile(self: *Self, pos: Pos) Tile {
    const chunk = self.getChunk(@divTrunc(pos, Chunk.s));
    if (chunk == null) return .{ .m = .border };
    return chunk.?.getTile(@rem(pos, Chunk.s));
}

pub inline fn setTile(self: *Self, pos: Pos, tile: Tile) void {
    const chunk = self.getChunk(@divTrunc(pos, Chunk.s));
    if (chunk == null) return;
    chunk.?.setTile(@rem(pos, Chunk.s), tile);
}

pub const Chunk = @import("Map/Chunk.zig");
pub const Tile = @import("Map/Tile.zig");

const Self = @This();
const Allocator = std.mem.Allocator;
const Size = @Vector(2, i32);
const Seed = i32;
const Pos = @Vector(2, i32);

const std = @import("std");
const log = @import("log");

// DEAD CODE
//    const value_gen = Noise{
//        .seed = config.seed,
//        .noise_type = .value,
//    };
//    const cellular_gen = Noise{
//        .seed = config.seed,
//        .noise_type = .cellular,
//    };
//
//    var pos: Pos = .{ 0, 0 };
//    while (pos[1] < Chunk.w * world.size[]) : (pos[1] += 1) { // BLOCK POS Y
//        pos[0] = 0;
//        while (pos[0] < Chunk.w * world.size[]) : (pos[0] += 1) { // BLOCK POS X
//
//            const xf = @as(f32, @floatFromInt(pos[0]));
//            const yf = @as(f32, @floatFromInt(pos[1]));
//
//            const noise: f32 = value_gen.noise2(
//                xf * 5,
//                yf * 5,
//            ) * 3 + cellular_gen.noise2(
//                xf * 3,
//                yf * 3,
//            ) * 2 + 20;
//
//            const tile = Tile{
//                .h = @intFromFloat(noise),
//                .m = .dirt,
//            };
//
//            world.setTile(pos, tile);
//        }
//    }
