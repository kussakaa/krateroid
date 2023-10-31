const std = @import("std");
const c = @import("c.zig");
const gl = @import("gl.zig");

const Allocator = std.mem.Allocator;

pub const State = struct {
    allocator: Allocator,
    chunks: std.ArrayListUnmanaged(Chunk),
    seed: u32 = 0,

    pub fn init(allocator: Allocator) State {
        return State{
            .allocator = allocator,
            .chunks = std.ArrayListUnmanaged(Chunk).init(allocator),
        };
    }
};

pub const Chunk = struct {
    pos: Pos = .{ 0, 0 },
    edit: u32 = 0,
    update: u32 = 0,
    hmap: HMap,

    pub const width = 32;

    const Pos = @Vector(2, i32);
    const HMap = [width][width]u8;

    const InitInfo = struct {
        pos: Pos,
    };

    pub fn init(info: InitInfo) !Chunk {
        var hmap: HMap = undefined;

        var noise_value = c.fnlCreateState();
        var noise_cellular = c.fnlCreateState();
        noise_value.noise_type = c.FNL_NOISE_VALUE;
        noise_cellular.noise_type = c.FNL_NOISE_CELLULAR;

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

pub const RenderSystem = struct {
    // pub fn render(state: *State) !void {}
    // pub fn draw(state: State) !void {}
};
