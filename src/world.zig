const std = @import("std");
const log = std.log.scoped(.world);
const c = @import("c.zig");

const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;

const lm = @import("linmath.zig");
const Vec = lm.Vec;
const Color = lm.Vec;

pub const Line = @import("world/Line.zig");
pub const Chunk = @import("world/Chunk.zig");
pub const width = 4; // width in chunks

var allocator: Allocator = undefined;
var seed: i32 = undefined;
pub var lines: Array(Line) = undefined;
pub var chunks: [width][width]?*Chunk = undefined;

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    seed: i32 = 2739,
}) !void {
    allocator = info.allocator;
    lines = try Array(Line).initCapacity(allocator, 32);
    seed = info.seed;
    for (0..width) |y| {
        for (0..width) |x| {
            chunks[y][x] = null;
        }
    }
}

pub fn deinit() void {
    lines.deinit(allocator);
    for (0..width) |y| {
        for (0..width) |x| {
            if (chunks[y][x] != null) allocator.destroy(chunks[y][x].?);
        }
    }
}

pub fn line(info: struct {
    p1: Vec,
    p2: Vec,
    color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
    hidden: bool = false,
}) !*Line {
    try lines.append(allocator, .{
        .p1 = info.p1,
        .p2 = info.p2,
        .color = info.color,
        .hidden = info.hidden,
    });
    return &lines.items[lines.items.len - 1];
}

pub fn chunk(info: struct {
    pos: Chunk.Pos,
}) !*Chunk {
    var noise_value = c.fnlCreateState();
    noise_value.noise_type = c.FNL_NOISE_VALUE;
    noise_value.seed = @intCast(seed);
    var noise_cellular = c.fnlCreateState();
    noise_cellular.noise_type = c.FNL_NOISE_CELLULAR;
    noise_cellular.seed = @intCast(seed);

    chunks[@intCast(info.pos[1])][@intCast(info.pos[0])] = try allocator.create(Chunk);
    var hmap = &chunks[@intCast(info.pos[1])][@intCast(info.pos[0])].?.hmap;
    var mmap = &chunks[@intCast(info.pos[1])][@intCast(info.pos[0])].?.mmap;

    for (0..Chunk.width) |y| {
        for (0..Chunk.width) |x| {
            //const value = c.fnlGetNoise2D(
            //    &noise_value,
            //    @as(f32, @floatFromInt(x)),
            //    @as(f32, @floatFromInt(y)),
            //);

            const cellular: f32 = c.fnlGetNoise2D(
                &noise_cellular,
                @as(f32, @floatFromInt(x)) * 7.0,
                @as(f32, @floatFromInt(y)) * 7.0,
            );

            hmap[y][x] = @as(u8, @intFromFloat(@max(0.0, (cellular + 1.0) * 7.0)));
            mmap[y][x] = 1;
        }
    }

    return chunks[@intCast(info.pos[1])][@intCast(info.pos[0])].?;
}
