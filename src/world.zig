const c = @import("c.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

const ChunkPos = @Vector(2, i32);

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
    pos: ChunkPos = .{ 0, 0 },
    edit: u32 = 0,
    update: u32 = 0,
    blocks: Blocks,

    pub const width = 32;
    pub const Blocks = [width][width][width]Block;

    pub fn init(pos: ChunkPos) !Chunk {
        var blocks: Blocks = undefined;
        for (0..width) |z| {
            for (0..width) |y| {
                for (0..width) |x| {
                    blocks[z][y][x] = .air;
                }
            }
        }
        return Chunk{
            .pos = pos,
            .blocks = blocks,
        };
    }

    fn generate(self: *Chunk) void {
        @setRuntimeSafety(false);
        var noise_value = c.fnlCreateState();
        noise_value.noise_type = c.FNL_NOISE_VALUE;
        var noise_cellular = c.fnlCreateState();
        noise_cellular.noise_type = c.FNL_NOISE_CELLULAR;

        for (0..width) |z| {
            for (0..width) |y| {
                for (0..width) |x| {
                    const value = c.fnlGetNoise2D(
                        &noise_value,
                        @as(f32, @floatFromInt((self.pos[0] * @as(i32, @intCast(width)) + @as(i32, @intCast(x))) * 3)),
                        @as(f32, @floatFromInt((self.pos[1] * @as(i32, @intCast(width)) + @as(i32, @intCast(y))) * 3)),
                    );

                    const cellular = c.fnlGetNoise2D(
                        &noise_cellular,
                        @as(f32, @floatFromInt((self.pos[0] * @as(i32, @intCast(width)) + @as(i32, @intCast(x))) * 3)),
                        @as(f32, @floatFromInt((self.pos[1] * @as(i32, @intCast(width)) + @as(i32, @intCast(y))) * 3)),
                    );

                    if (@as(f32, @floatFromInt(z)) < (value + cellular) * 15.0 + 32.0) {
                        self.blocks[z][y][x] = Block.block;
                    } else {
                        self.blocks[z][y][x] = Block.air;
                    }
                }
            }
        }
    }
};

pub const Block = enum {
    air,
    stone,
};

pub const RenderSystem = struct {
    // pub fn render(state: *State) !void {}
    // pub fn draw(state: State) !void {}
};
