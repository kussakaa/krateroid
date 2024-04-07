const std = @import("std");
const log = std.log.scoped(.terra);
const testing = std.testing;
const zm = @import("zmath");
const znoise = @import("znoise");

const Noise = znoise.FnlGenerator;
const Allocator = std.mem.Allocator;

// CONSTS

pub const w = 4;
pub const h = 2;
pub const v = w * w * h;
pub const chunk_w = 32;
pub const chunk_v = chunk_w * chunk_w * chunk_w;

// TYPES

pub const BlockId = usize;
pub const BlockPos = @Vector(3, u32);
pub const Block = enum(u8) {
    air = 0,
    stone,
    dirt,
    sand,
};

pub const ChunkId = usize;
pub const ChunkPos = @Vector(3, u32);
pub const ChunkBlocks = struct { data: ChunkBlocksData };
pub const ChunkBlocksData = [chunk_v]Block;

// STATE

var _allocator: Allocator = undefined;
var _seed: i32 = 0;

const _chunks = struct {
    var init: [v]bool = undefined;
    var block: [v]*ChunkBlocks = undefined;
};

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    seed: i32 = 0,
}) !void {
    _allocator = info.allocator;
    _seed = info.seed;
    @memset(_chunks.init[0..], false);
    for (0..v) |i| {
        try initChunk(i);
        genChunk(i);
    }
}

pub fn deinit() void {
    for (_chunks.init[0..], 0..) |chunk_init, i| if (chunk_init) deinitChunk(i);
}

pub fn update() void {}

fn initChunks() !void {}

pub fn initChunk(id: ChunkId) !void {
    _chunks.init[id] = true;
    _chunks.block[id] = try _allocator.create(ChunkBlocks);
}

pub fn deinitChunk(id: ChunkId) void {
    _chunks.init[id] = false;
    _allocator.destroy(_chunks.block[id]);
}

pub fn genChunk(id: ChunkId) void {
    const pos = chunkPosFromChunkId(id);
    var blocks = getChunkBlocksDataPtr(id);

    const value_gen = Noise{
        .seed = _seed,
        .noise_type = .value,
    };

    const cellular_gen = Noise{
        .seed = _seed,
        .noise_type = .cellular,
    };

    var z: u32 = 0;
    while (z < chunk_w) : (z += 1) {
        var y: u32 = 0;
        while (y < chunk_w) : (y += 1) {
            var x: u32 = 0;
            while (x < chunk_w) : (x += 1) {
                const value: f32 = value_gen.noise2(
                    @as(f32, @floatFromInt(x + pos[0] * chunk_w)) * 3.0,
                    @as(f32, @floatFromInt(y + pos[1] * chunk_w)) * 3.0,
                );

                const cellular: f32 = cellular_gen.noise2(
                    @as(f32, @floatFromInt(x + pos[0] * chunk_w)) * 3.0,
                    @as(f32, @floatFromInt(y + pos[1] * chunk_w)) * 3.0,
                );

                const noise_stone = (value + 1.0) * 5.0 + (cellular + 1.0) * 20.0 + 10.0;
                const noise_dirt = (value + 1.0) * 3.0 + (cellular + 1.0) * 5.0 + 20.0;

                const block: Block =
                    if (@as(f32, @floatFromInt(z + pos[2] * chunk_w)) < noise_stone)
                    .stone
                else if (@as(f32, @floatFromInt(z + pos[2] * chunk_w)) < noise_dirt)
                    .dirt
                else
                    .air;

                blocks[blockIdFromBlockPos(.{ x, y, z })] = block;
            }
        }
    }
}

pub inline fn isInitChunk(id: ChunkId) bool {
    return if (id < v) _chunks.init[id] else false;
}

pub inline fn isInitChunkFromPos(pos: ChunkPos) bool {
    return if (pos[0] < w and pos[1] < w and pos[2] < h)
        _chunks.init[chunkIdFromChunkPos(pos)]
    else
        false;
}

pub inline fn getBlock(pos: BlockPos) Block {
    const chunk_id = chunkIdFromChunkPos(chunkPosFromBlockPos(pos));
    const block_id = blockIdFromBlockPos(pos % BlockPos{ chunk_w, chunk_w, chunk_w });
    return _chunks.block[chunk_id].data[block_id];
}

pub inline fn setBlock(pos: BlockPos, block: Block) void {
    const chunk_id = chunkIdFromChunkPos(chunkPosFromBlockPos(pos));
    const block_id = blockIdFromBlockPos(pos % BlockPos{ chunk_w, chunk_w, chunk_w });
    _chunks.block[chunk_id].?.data[block_id] = block;
}

pub inline fn getChunkBlocksDataPtr(id: ChunkId) *ChunkBlocksData {
    return &_chunks.block[id].data;
}

pub inline fn chunkPosFromChunkId(id: ChunkId) ChunkPos {
    const idu32: u32 = @intCast(id);
    return .{
        @rem(idu32, w),
        @rem(@divTrunc(idu32, w), w),
        @divTrunc(@divTrunc(idu32, w), w),
    };
}

pub inline fn chunkIdFromChunkPos(pos: ChunkPos) usize {
    return pos[0] + pos[1] * w + pos[2] * w * w;
}

test "world.chunkPosFromChunkId and world.chunkIdFromChunkPos" {
    try std.testing.expectEqual(chunkPosFromChunkId(chunkIdFromChunkPos(.{ 0, 0, 0 })), ChunkPos{ 0, 0, 0 });
    try std.testing.expectEqual(chunkPosFromChunkId(chunkIdFromChunkPos(.{ 3, 0, 0 })), ChunkPos{ 3, 0, 0 });
    try std.testing.expectEqual(chunkPosFromChunkId(chunkIdFromChunkPos(.{ 2, 0, 0 })), ChunkPos{ 2, 0, 0 });
    try std.testing.expectEqual(chunkPosFromChunkId(chunkIdFromChunkPos(.{ 2, 1, 3 })), ChunkPos{ 2, 1, 3 });
    try std.testing.expectEqual(chunkPosFromChunkId(chunkIdFromChunkPos(.{ 2, 2, 2 })), ChunkPos{ 2, 2, 2 });
    try std.testing.expectEqual(chunkPosFromChunkId(chunkIdFromChunkPos(.{ 3, 3, 3 })), ChunkPos{ 3, 3, 3 });
}

pub inline fn chunkPosFromBlockPos(pos: BlockPos) BlockPos {
    return @divTrunc(pos, ChunkPos{ chunk_w, chunk_w, chunk_w });
}

pub inline fn blockIdFromBlockPos(pos: BlockPos) usize {
    return pos[0] + pos[1] * chunk_w + pos[2] * chunk_w * chunk_w;
}

pub inline fn blockPosFromBlockId(id: ChunkId) ChunkPos {
    return .{
        id % chunk_w,
        (id / chunk_w) % chunk_w,
        (id / chunk_w) / chunk_w,
    };
}

test "world.blockPosFromBlockId and world.blockIdFromBlockPos" {
    try std.testing.expectEqual(blockPosFromBlockId(blockIdFromBlockPos(.{ 0, 0, 0 })), BlockPos{ 0, 0, 0 });
    try std.testing.expectEqual(blockPosFromBlockId(blockIdFromBlockPos(.{ 13, 0, 0 })), BlockPos{ 13, 0, 0 });
    try std.testing.expectEqual(blockPosFromBlockId(blockIdFromBlockPos(.{ 0, 31, 0 })), BlockPos{ 0, 31, 0 });
    try std.testing.expectEqual(blockPosFromBlockId(blockIdFromBlockPos(.{ 0, 0, 16 })), BlockPos{ 0, 0, 16 });
    try std.testing.expectEqual(blockPosFromBlockId(blockIdFromBlockPos(.{ 10, 22, 10 })), BlockPos{ 10, 22, 10 });
    try std.testing.expectEqual(blockPosFromBlockId(blockIdFromBlockPos(.{ 31, 31, 31 })), BlockPos{ 31, 31, 31 });
}
