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
            if (chunks[y][x]) |item| _allocator.destroy(item);
        }
    }
}

pub fn chunk(info: struct {
    pos: @Vector(2, u32),
}) !*Chunk {
    if (chunks[@intCast(info.pos[1])][@intCast(info.pos[0])]) |item| {
        return item;
    }

    var item = try _allocator.create(Chunk);
    chunks[@intCast(info.pos[1])][@intCast(info.pos[0])] = item;

    const value_gen = Noise{
        .seed = seed,
        .noise_type = .value,
    };

    for (0..Chunk.width) |z| {
        for (0..Chunk.width) |y| {
            for (0..Chunk.width) |x| {
                const value: f32 = value_gen.noise2(
                    @as(f32, @floatFromInt(x + info.pos[0] * Chunk.width)) * 10.0,
                    @as(f32, @floatFromInt(y + info.pos[1] * Chunk.width)) * 10.0,
                );

                item.grid[z][y][x] = @as(f32, @floatFromInt(z)) < (value + 1.0) * 5.0;
            }
        }
    }

    return item;
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
