const std = @import("std");
const log = std.log.scoped(.world);
const c = @import("c.zig");

const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;

var _allocator: Allocator = undefined,
var _seed: u32 = 0,
var chunks: std.Array(Chunk) = undefined,

pub fn init(info: struct { allocator: Allocator, seed: u32 = 0 }) !void {
    _allocator = info.allocator;
    _seed = info.seed;
    chunks = std.Array(Chunk).initCapacity(_allocator, 16);
}

pub const Chunk = struct {

    pub fn init(info: InitInfo) !Chunk {
        var hmap: HMap = undefined;

        var noise_value = c.fnlCreateState();
        noise_value.noise_type = c.FNL_NOISE_VALUE;
        noise_value.seed = info.seed;
        var noise_cellular = c.fnlCreateState();
        noise_cellular.noise_type = c.FNL_NOISE_CELLULAR;
        noise_cellular.seed = info.seed;

        for (0..width) |y| {
            for (0..width) |x| {
                const value = c.fnlGetNoise2D(
                    &noise_value,
                    @as(f32, @floatFromInt((info.pos[0] * @as(i32, @intCast(width)) + @as(i32, @intCast(x))) * 3)),
                    @as(f32, @floatFromInt((info.pos[1] * @as(i32, @intCast(width)) + @as(i32, @intCast(y))) * 3)),
                );

                const cellular = c.fnlGetNoise2D(
                    &noise_cellular,
                    @as(f32, @floatFromInt((info.pos[0] * @as(i32, @intCast(width)) + @as(i32, @intCast(x))) * 3)),
                    @as(f32, @floatFromInt((info.pos[1] * @as(i32, @intCast(width)) + @as(i32, @intCast(y))) * 3)),
                );

                hmap[y][x] = @as(u8, @intFromFloat((value + cellular) * 15.0 + 32.0));
            }
        }

        return Chunk{
            .pos = info.pos,
            .hmap = hmap,
        };
    }
};
