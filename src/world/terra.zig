const std = @import("std");
const Array = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const Noise = @import("znoise").FnlGenerator;

pub const w = 4; // width in chunks
pub const h = 2; // height in chunks
pub const v = w * w * h;

pub const Seed = i32;
pub const Block = @import("terra/Block.zig");
pub const Chunk = @import("terra/Chunk.zig");

var _allocator: Allocator = undefined;
var _chunks: [v]?*Chunk = undefined;
var _seed: Seed = undefined;

pub fn init(info: struct {
    allocator: Allocator,
    seed: i32,
}) !void {
    _allocator = info.allocator;
    _seed = info.seed;
    @memset(_chunks[0..], null);
}

pub fn deinit() void {
    for (_chunks[0..]) |item| if (item != null) _allocator.destroy(item.?);
}

pub fn initChunk(pos: Chunk.Pos) !void {
    if (isInitChunk(pos)) return;

    var chunk = try _allocator.create(Chunk);

    const value_gen = Noise{
        .seed = _seed,
        .noise_type = .value,
    };

    const cellular_gen = Noise{
        .seed = _seed,
        .noise_type = .cellular,
    };

    for (0..Chunk.w) |z| {
        for (0..Chunk.w) |y| {
            for (0..Chunk.w) |x| {
                const value: f32 = value_gen.noise2(
                    @as(f32, @floatFromInt(x + pos[0] * Chunk.w)) * 3.0,
                    @as(f32, @floatFromInt(y + pos[1] * Chunk.w)) * 3.0,
                );

                const cellular: f32 = cellular_gen.noise2(
                    @as(f32, @floatFromInt(x + pos[0] * Chunk.w)) * 3.0,
                    @as(f32, @floatFromInt(y + pos[1] * Chunk.w)) * 3.0,
                );

                const block = Block{ .id = @as(u8, @intFromBool(@as(f32, @floatFromInt(z + pos[2] * Chunk.w)) < (value + 1.0) * 5.0 + (cellular + 1.0) * 20.0 + 10.0)) };
                chunk.setBlock(.{ @intCast(x), @intCast(y), @intCast(z) }, block);
            }
        }
    }

    _chunks[@intCast(chunkIndexFromChunkPos(pos))] = chunk;
}

pub inline fn isInitChunk(pos: Chunk.Pos) bool {
    return if (pos[0] < w and pos[1] < w and pos[2] < h and _chunks[@intCast(chunkIndexFromChunkPos(pos))] != null) true else false;
}

pub inline fn getBlock(pos: Block.Pos) Block {
    return _chunks[@intCast(chunkIndexFromChunkPos(chunkPosFromBlockPos(pos)))].?.getBlock(pos % Block.Pos{ Chunk.w, Chunk.w, Chunk.w });
}

pub inline fn chunkIndexFromChunkPos(pos: Chunk.Pos) u32 {
    return pos[0] + pos[1] * w + pos[2] * w * w;
}

pub inline fn chunkPosFromBlockPos(pos: Block.Pos) Chunk.Pos {
    return @divTrunc(pos, Chunk.Pos{ Chunk.w, Chunk.w, Chunk.w });
}
