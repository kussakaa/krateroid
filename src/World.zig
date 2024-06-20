const std = @import("std");
const log = std.log.scoped(.world);
const assert = std.debug.assert;

const znoise = @import("znoise");
const Noise = znoise.FnlGenerator;

const World = @This();

allocator: std.mem.Allocator,
width: usize = 0,
chunks: []?*Chunk = undefined,

pub fn init(allocator: std.mem.Allocator) World {
    return .{
        .allocator = allocator,
    };
}

pub fn deinit(self: *World) void {
    self.free();
    self.* = undefined;
}

pub const GenerateConfig = struct {
    width: usize,
    seed: i32 = 6969,
};

pub fn generate(world: *World, config: GenerateConfig) !void {
    assert(world.width == 0);
    world.chunks = try world.allocator.alloc(?*Chunk, config.width * config.width);
    world.width = config.width;
    @memset(world.chunks[0..], null);

    //    var chunk_pos: @Vector(2, i32) = .{ 0, 0 };
    //    const value_gen = Noise{
    //        .seed = generate.seed,
    //        .noise_type = .value,
    //    };
    //    const cellular_gen = Noise{
    //        .seed = generate.seed,
    //        .noise_type = .cellular,
    //    };
    //    var z: u32 = 0;
    //    while (z < Chunk.height) : (z += 1) {
    //        var y: u32 = 0;
    //        while (y < Chunk.width) : (y += 1) {
    //            var x: u32 = 0;
    //            while (x < Chunk.width) : (x += 1) {
    //                const xf = @as(f32, @floatFromInt(x + generate.pos[0] * w));
    //                const yf = @as(f32, @floatFromInt(y + generate.pos[1] * w));
    //                const zf = @as(f32, @floatFromInt(z));
    //
    //                const noise_stone: f32 = value_gen.noise2(
    //                    xf * 5,
    //                    yf * 5,
    //                ) * 12 + cellular_gen.noise2(
    //                    xf * 5,
    //                    yf * 5,
    //                ) * 12 + 25;
    //
    //                const noise_dirt: f32 = value_gen.noise2(
    //                    xf * 5,
    //                    yf * 5,
    //                ) * 3 + cellular_gen.noise2(
    //                    xf * 3,
    //                    yf * 3,
    //                ) * 2 + 20;
    //
    //                const noise_sand: f32 = cellular_gen.noise2(
    //                    xf * 6,
    //                    yf * 6,
    //                ) * 3 + cellular_gen.noise2(
    //                    xf * 9,
    //                    yf * 9,
    //                ) * 3 + 23;
    //
    //                const block: Block = if (zf < noise_stone)
    //                    .stone
    //                else if (zf < noise_dirt)
    //                    .dirt
    //                else if (zf < noise_sand)
    //                    .sand
    //                else
    //                    .air;
    //
    //                result.setBlock(.{ x, y, z }, block);
    //            }
    //        }
    //    }
}

pub fn load() !void {}

pub fn free(world: *World) void {
    assert(world.width != 0);
    world.allocator.free(world.chunks);
    world.width = 0;
}

pub fn getChunk(world: *World, pos: @Vector(2, i32)) ?*Chunk {
    return if (pos[1] >= world.width or pos[0] >= world.width or pos[0] < 0 or pos[1] < 0)
        null
    else
        world.chunks[@intCast(pos[0] + pos[1] * world.width)];
}

pub fn getBlock(world: *World, pos: @Vector(3, i32)) Block {
    const chunk = world.getChunk(.{ pos[0] / Chunk.width, pos[1] / Chunk.width });
    if (pos[2] >= Chunk.height or pos[2] <= 0 or chunk == null) return .air;
    const block = chunk.getBlock(pos % Chunk.size);
    return block;
}

pub const Block = enum(u8) {
    air = 0,
    stone = 1,
    dirt = 2,
    sand = 3,
};

pub const Chunk = struct {
    pub const width = 16;
    pub const height = 64;
    pub const size = @Vector(3, u8){ width, width, height };
    pub const volume = width * width * height;

    blocks: [volume]Block,

    pub inline fn getBlock(chunk: *Chunk, pos: @Vector(3, i32)) Block {
        return chunk.blocks[@intCast(pos[0] + pos[1] * width + pos[2] * width * width)];
    }
};
