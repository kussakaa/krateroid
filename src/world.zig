const std = @import("std");
const log = std.log.scoped(.world);
const testing = std.testing;
const zm = @import("zmath");
const znoise = @import("znoise");
const Noise = znoise.FnlGenerator;

const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;

// CONSTANTS

const terra_w = 4;
const terra_h = 3;
const terra_v = terra_w * terra_w * terra_h;
const chunk_w = 32;
const chunk_v = chunk_w * chunk_w * chunk_w;

// TYPES

pub const BlockId = usize;
pub const BlockPos = @Vector(3, u32);
pub const Block = enum(u8) {
    air,
    dirt,
    grass,
    sand,
    stone,
};

pub const ChunkId = usize;
pub const ChunkPos = @Vector(3, u32);
pub const ChunkBlocks = struct { data: ChunkBlocksData };
pub const ChunkBlocksData = [chunk_v]Block;

// STATE

var _allocator: Allocator = undefined;
var _seed: i32 = 0;

const _chunks = struct {
    var init: [terra_v]bool = undefined;
    var block: [terra_v]*ChunkBlocks = undefined;
};

const _actors = struct {};

const _projectiles = struct {
    const max_cnt = 1024;
    var pos: [max_cnt]zm.F32x4 = undefined;
    var dir: [max_cnt]zm.F32x4 = undefined;
};

const _explosions = struct {};

// WORLD

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    seed: i32 = 0,
}) !void {
    _allocator = info.allocator;
    _seed = info.seed;
    try initChunks();
    initProjectiles();
    //    initExplosions();
}

pub fn deinit() void {
    deinitChunks();
    deinitProjectiles();
    //    deinitExplosions();
}

pub fn update() void {
    updateChunks();
    updateProjectiles();
    //    updateExplosions();
}

// CHUNKS

fn initChunks() !void {
    @memset(_chunks.init[0..], false);
    for (0..terra_v) |i| {
        try initChunk(i);
        genChunk(i);
    }
}

fn deinitChunks() void {
    for (_chunks.init[0..], 0..) |chunk_init, i| if (chunk_init) deinitChunk(i);
}

fn updateChunks() void {}

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

                const n = (value + 1.0) * 5.0 + (cellular + 1.0) * 20.0 + 10.0;
                const block: Block = if (@as(f32, @floatFromInt(z + pos[2] * chunk_w)) < n) .dirt else .air;

                blocks[blockIdFromBlockPos(.{ x, y, z })] = block;
            }
        }
    }
}

pub inline fn getTerraW() comptime_int {
    return terra_w;
}

pub inline fn getTerraH() comptime_int {
    return terra_h;
}

pub inline fn getTerraV() comptime_int {
    return terra_v;
}

pub inline fn getChunkW() comptime_int {
    return chunk_w;
}

pub inline fn getChunkV() comptime_int {
    return chunk_v;
}

pub inline fn isInitChunk(id: ChunkId) bool {
    return if (id < terra_v) _chunks.init[id] else false;
}

pub inline fn isInitChunkFromPos(pos: ChunkPos) bool {
    return if (pos[0] < terra_w and pos[1] < terra_w and pos[2] < terra_h)
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
        @rem(idu32, terra_w),
        @rem(@divTrunc(idu32, terra_w), terra_w),
        @divTrunc(@divTrunc(idu32, terra_w), terra_w),
    };
}

pub inline fn chunkIdFromChunkPos(pos: ChunkPos) usize {
    return pos[0] + pos[1] * terra_w + pos[2] * terra_w * terra_w;
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

// PROJECTILES

pub fn initProjectiles() void {
    @memset(_projectiles.pos[0..], zm.f32x4s(0.0));
    @memset(_projectiles.dir[0..], zm.f32x4s(0.0));
}

pub fn deinitProjectiles() void {}
pub fn updateProjectiles() void {}

pub inline fn getProjectilesMaxCnt() comptime_int {
    return _projectiles.max_cnt;
}

pub inline fn getProjectilesPosBytes() []const u8 {
    return std.mem.sliceAsBytes(_projectiles.pos[0..]);
}
