const c = @import("c.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const linmath = @import("linmath.zig");
const ChunkPos = @Vector(3, i32);
const Vec3 = linmath.F32x3;

pub const State = struct {
    allocator: Allocator,
    chunks: std.ArrayListUnmanaged(Chunk),
    seed: u32 = 0,

    pub fn init(allocator: Allocator) World {
        return World{
            .allocator = allocator,
            .chunks = std.ArrayListUnmanaged(Chunk).init(allocator),
        };
    }
};

pub const Chunk = struct {
    blocks: [width * width * width]Block,
    pos: ChunkPos = .{ 0, 0 },
    edit: u32 = 0,
    update: u32 = 0,

    pub const width = 32;

    pub fn init() !Chunk {}

    pub fn deinit() void {}

    fn generate(self: *Chunk) void {
        @setRuntimeSafety(false);
        var noise_velue = c.fnlCreateState();
        noise_velue.noise_type = c.FNL_NOISE_VALUE;
        var noise_cellular = c.fnlCreateState();
        noise_cellular.noise_type = c.FNL_NOISE_CELLULAR;

        for (0..height) |z| {
            for (0..height) |y| {
                for (0..height) |x| {
                    const velue = c.fnlGetNoise2D(
                        &noise_velue,
                        @as(f32, @floatFromInt((self.pos[0] * @as(i32, @intCast(width)) + @as(i32, @intCast(x))) * 3)),
                        @as(f32, @floatFromInt((self.pos[1] * @as(i32, @intCast(width)) + @as(i32, @intCast(y))) * 3)),
                    );

                    const cellular = c.fnlGetNoise2D(
                        &noise_cellular,
                        @as(f32, @floatFromInt((self.pos[0] * @as(i32, @intCast(width)) + @as(i32, @intCast(x))) * 3)),
                        @as(f32, @floatFromInt((self.pos[1] * @as(i32, @intCast(width)) + @as(i32, @intCast(y))) * 3)),
                    );

                    if (@as(f32, @floatFromInt(z)) < (velue + cellular) * 15.0 + 32.0) {
                        self.grid[z][y][x] = Cell.block;
                    } else {
                        self.grid[z][y][x] = Cell.air;
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
    pub fn render(state: *State) !void {}
    pub fn draw(state: *State) !void {}
};
