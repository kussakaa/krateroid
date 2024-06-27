allocator: Allocator,
width: i32,
chunks: []?*Chunk,

pub const Config = struct {
    allocator: Allocator,
    width: i32 = 4,
    seed: i32 = 6969,
};

pub fn init(config: Config) anyerror!World {
    assert(config.width > 0);

    var world = World{
        .allocator = config.allocator,
        .width = config.width,
        .chunks = try config.allocator.alloc(?*Chunk, @intCast(config.width * config.width)),
    };

    @memset(world.chunks[0..], null);

    world.chunks[0] = try world.allocator.create(Chunk);

    const value_gen = Noise{
        .seed = config.seed,
        .noise_type = .value,
    };
    const cellular_gen = Noise{
        .seed = config.seed,
        .noise_type = .cellular,
    };

    var pos: Pos = .{ 0, 0 };
    while (pos[1] < Chunk.w * world.width) : (pos[1] += 1) { // BLOCK POS Y
        pos[0] = 0;
        while (pos[0] < Chunk.w * world.width) : (pos[0] += 1) { // BLOCK POS X

            const xf = @as(f32, @floatFromInt(pos[0]));
            const yf = @as(f32, @floatFromInt(pos[1]));

            const noise: f32 = value_gen.noise2(
                xf * 5,
                yf * 5,
            ) * 3 + cellular_gen.noise2(
                xf * 3,
                yf * 3,
            ) * 2 + 20;

            const tile = Tile{
                .h = @intFromFloat(noise),
                .m = .dirt,
            };

            world.setTile(pos, tile);
        }
    }

    log.succes("Initialization World", .{});

    return world;
}

pub fn deinit(self: *World) void {
    assert(self.width != 0);
    self.allocator.destroy(self.chunks[0].?);
    self.allocator.free(self.chunks);
    self.width = 0;
    self.* = undefined;
}

pub inline fn getChunk(self: *World, pos: @Vector(2, i32)) ?*Chunk {
    return if (pos[1] >= self.width or pos[0] >= self.width or pos[0] < 0 or pos[1] < 0)
        null
    else
        self.chunks[@intCast(pos[0] + pos[1] * self.width)];
}

pub inline fn getTile(self: *World, pos: Pos) Tile {
    const chunk = self.getChunk(@divTrunc(pos, Chunk.s));
    if (chunk == null) return .{ .m = .border };
    return chunk.?.getTile(@rem(pos, Chunk.s));
}

pub inline fn setTile(self: *World, pos: Pos, tile: Tile) void {
    const chunk = self.getChunk(@divTrunc(pos, Chunk.s));
    if (chunk == null) return;
    chunk.?.setTile(@rem(pos, Chunk.s), tile);
}

pub const Tile = struct {
    h: H = 0,
    m: M,

    const H = u8;
    const M = enum(u8) {
        border = 0,
        dirt,
        stone,
    };
};

const Chunk = struct {
    tiles: [v]Tile,

    pub const w = 32;
    pub const s = Pos{ w, w };
    pub const v = w * w;

    pub inline fn getTile(chunk: *Chunk, pos: Pos) Tile {
        return chunk.tiles[@intCast(pos[0] + pos[1] * w)];
    }

    pub inline fn setTile(chunk: *Chunk, pos: Pos, tile: Tile) void {
        chunk.tiles[@intCast(pos[0] + pos[1] * w)] = tile;
    }
};

const World = @This();
const Pos = @Vector(2, i32);
const Allocator = std.mem.Allocator;

const std = @import("std");
const log = @import("log.zig");
const assert = std.debug.assert;
const znoise = @import("znoise");
const Noise = znoise.FnlGenerator;
