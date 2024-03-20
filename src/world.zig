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
            if (chunk.isInit(.{ x, y })) chunk.deinit(.{ x, y });
        }
    }
}

pub const chunk = struct {
    pub fn init(pos: Chunk.Pos) !void {
        if (isInit(pos)) {
            return;
        }

        var item = try _allocator.create(Chunk);

        chunks[pos[1]][pos[0]] = item;

        const value_gen = Noise{
            .seed = seed,
            .noise_type = .value,
        };

        const cellular_gen = Noise{
            .seed = seed,
            .noise_type = .cellular,
        };

        for (0..Chunk.width) |z| {
            for (0..Chunk.width) |y| {
                for (0..Chunk.width) |x| {
                    const value: f32 = value_gen.noise2(
                        @as(f32, @floatFromInt(x + pos[0] * Chunk.width)) * 3.0,
                        @as(f32, @floatFromInt(y + pos[1] * Chunk.width)) * 3.0,
                    );

                    const cellular: f32 = cellular_gen.noise2(
                        @as(f32, @floatFromInt(x + pos[0] * Chunk.width)) * 10.0,
                        @as(f32, @floatFromInt(y + pos[1] * Chunk.width)) * 10.0,
                    );

                    item.blocks[z][y][x] = @as(f32, @floatFromInt(z)) < (value + 1.0) * 7.0 + (cellular + 1.0) * 3.0 + 5.0;
                }
            }
        }
    }

    pub fn deinit(pos: Chunk.Pos) void {
        _allocator.destroy(chunks[pos[1]][pos[0]].?);
        chunks[pos[1]][pos[0]] = null;
    }

    pub fn isInit(pos: Chunk.Pos) bool {
        return if (chunks[pos[1]][pos[0]] != null) true else false;
    }

    pub fn getPtr(pos: Chunk.Pos) ?*Chunk {
        return chunks[pos[1]][pos[0]];
    }

    pub fn getSlicePtrs(pos: Chunk.Pos) [3][3]?*Chunk {
        var result: [3][3]?*Chunk = undefined;

        result[0][0] = if (pos[0] > 0 and pos[1] > 0) chunks[pos[1] - 1][pos[0] - 1] else null;
        result[0][1] = if (pos[1] > 0) chunks[pos[1] - 1][pos[0]] else null;
        result[0][2] = if (pos[0] < width - 1 and pos[1] > 0) chunks[pos[1] - 1][pos[0] + 1] else null;
        result[1][0] = if (pos[0] > 0) chunks[pos[1]][pos[0] - 1] else null;
        result[1][1] = chunks[pos[1]][pos[0]];
        result[1][2] = if (pos[0] < width - 1) chunks[pos[1]][pos[0] + 1] else null;
        result[2][0] = if (pos[0] > 0 and pos[1] < width - 1) chunks[pos[1] + 1][pos[0] - 1] else null;
        result[2][1] = if (pos[1] < width - 1) chunks[pos[1] + 1][pos[0]] else null;
        result[2][2] = if (pos[0] < width - 1 and pos[1] < width - 1) chunks[pos[1] + 1][pos[0] + 1] else null;

        //        const xbegin = if (pos[0] > 0) pos[0] - 1 else 0;
        //        const xend = if (pos[0] < width - 1) pos[0] + 1 else width - 1;
        //        const ybegin = if (pos[1] > 0) pos[1] - 1 else 0;
        //        const yend = if (pos[1] < width - 1) pos[1] + 1 else width - 1;
        //        for (ybegin..yend) |y| {
        //            for (xbegin..xend) |x| {
        //                result[y + 1 - pos[1]][x + 1 - pos[0]] = chunks[y][x];
        //            }
        //        }

        return result;
    }
};

pub const line = struct {
    pub fn init(info: struct {
        p1: Vec,
        p2: Vec,
        color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
        show: bool = true,
    }) !Line.Id {
        try lines.append(_allocator, .{
            .id = lines.items.len,
            .p1 = info.p1,
            .p2 = info.p2,
            .color = info.color,
            .show = info.show,
        });
        return lines.items.len - 1;
    }
};
