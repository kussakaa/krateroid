const std = @import("std");
const log = std.log.scoped(.world);
const c = @import("c.zig");

const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;

pub const Chunk = @import("world/Chunk.zig");
pub const width = 4;

var allocator: Allocator = undefined;
var seed: u32 = undefined;
pub var chunks: [width][width]?*Chunk = undefined;

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    seed: u32 = 2739,
}) !void {
    allocator = info.allocator;
    seed = info.seed;
    for (0..width) |y| {
        for (0..width) |x| {
            chunks[y][x] = null;
        }
    }
}

pub fn deinit() void {
    for (0..width) |y| {
        for (0..width) |x| {
            if (chunks[y][x] != null) allocator.destroy(chunks[y][x].?);
        }
    }
}

pub fn chunk(info: struct { pos: Chunk.Pos }) !void {
    //var noise_value = c.fnlCreateState();
    //noise_value.noise_type = c.FNL_NOISE_VALUE;
    //noise_value.seed = _seed;
    //var noise_cellular = c.fnlCreateState();
    //noise_cellular.noise_type = c.FNL_NOISE_CELLULAR;
    //noise_cellular.seed = _seed;

    chunks[@intCast(info.pos[1])][@intCast(info.pos[0])] = try allocator.create(Chunk);
    var hmap = &chunks[@intCast(info.pos[1])][@intCast(info.pos[0])].?.hmap;
    var mmap = &chunks[@intCast(info.pos[1])][@intCast(info.pos[0])].?.mmap;

    for (0..Chunk.width) |y| {
        for (0..Chunk.width) |x| {
            hmap[y][x] = 10;
            mmap[y][x] = 1;

            //const value = c.fnlGetNoise2D(
            //    &noise_value,
            //    @as(f32, @floatFromInt((info.pos[0] * @as(i32, @intCast(width)) + @as(i32, @intCast(x))) * 3)),
            //    @as(f32, @floatFromInt((info.pos[1] * @as(i32, @intCast(width)) + @as(i32, @intCast(y))) * 3)),
            //);

            //const cellular = c.fnlGetNoise2D(
            //    &noise_cellular,
            //    @as(f32, @floatFromInt((info.pos[0] * @as(i32, @intCast(width)) + @as(i32, @intCast(x))) * 3)),
            //    @as(f32, @floatFromInt((info.pos[1] * @as(i32, @intCast(width)) + @as(i32, @intCast(y))) * 3)),
            //);

            //hmap[y][x] = @as(u8, @intFromFloat((value + cellular) * 15.0 + 32.0));
        }
    }
}
