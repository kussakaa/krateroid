const std = @import("std");
const log = std.log.scoped(.world);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;

const Noise = @import("znoise").FnlGenerator;

const zm = @import("zmath");
const Vec = zm.Vec;
const Color = zm.Vec;

pub const Line = @import("world/Line.zig");
pub const Chunk = @import("world/Chunk.zig");
pub const width = 4; // width in chunks

var _allocator: Allocator = undefined;
pub var seed: i32 = undefined;

pub var chunks: [width][width]?*Chunk = undefined;
pub var lines: Array(Line) = undefined;

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    seed: i32 = 0,
}) !void {
    _allocator = info.allocator;
    lines = try Array(Line).initCapacity(_allocator, 32);
    seed = info.seed;
    for (0..width) |y| {
        for (0..width) |x| {
            chunks[y][x] = null;
        }
    }
}

pub fn deinit() void {
    lines.deinit(_allocator);
    for (0..width) |y| {
        for (0..width) |x| {
            if (chunks[y][x] != null) _allocator.destroy(chunks[y][x].?);
        }
    }
}

pub fn chunk(info: struct {
    pos: Chunk.Pos,
}) !*Chunk {
    const value_gen = Noise{
        .seed = seed,
        .noise_type = .value,
    };
    const cellular_gen = Noise{
        .seed = seed,
        .noise_type = .cellular,
    };

    chunks[@intCast(info.pos[1])][@intCast(info.pos[0])] = try _allocator.create(Chunk);
    var hmap = &chunks[@intCast(info.pos[1])][@intCast(info.pos[0])].?.hmap;
    var mmap = &chunks[@intCast(info.pos[1])][@intCast(info.pos[0])].?.mmap;

    for (0..Chunk.width) |y| {
        for (0..Chunk.width) |x| {
            const value: f32 = value_gen.noise2(
                @as(f32, @floatFromInt(x)) * 7.0,
                @as(f32, @floatFromInt(y)) * 7.0,
            );

            const cellular: f32 = cellular_gen.noise2(
                @as(f32, @floatFromInt(x)) * 7.0,
                @as(f32, @floatFromInt(y)) * 7.0,
            );

            hmap[y][x] = @as(u8, @intFromFloat(@max(0.0, (cellular + value + 1.0) * 7.0)));
            mmap[y][x] = 1;
        }
    }

    return chunks[@intCast(info.pos[1])][@intCast(info.pos[0])].?;
}

pub fn line(info: struct {
    p1: Vec,
    p2: Vec,
    color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
    show: bool = true,
}) !*Line {
    try lines.append(_allocator, .{
        .p1 = info.p1,
        .p2 = info.p2,
        .color = info.color,
        .show = info.show,
    });
    return &lines.items[lines.items.len - 1];
}
