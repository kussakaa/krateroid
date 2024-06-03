const std = @import("std");
const log = std.log.scoped(.terra);

const gfx = @import("gfx");

const Camera = @import("Camera.zig");

const Allocator = std.mem.Allocator;

const znoise = @import("znoise");
const Noise = znoise.FnlGenerator;

pub const Block = enum(u8) {
    air = 0,
    stone = 1,
    dirt = 2,
    sand = 3,
};

pub const Chunk = struct {
    pub const w = 16;
    pub const h = 64;
    pub const s = @Vector(3, u8){ w, w, h };
    pub const v = w * w * h;

    const Self = @This();

    blocks: [v]Block,

    pub fn create(
        allocator: Allocator,
        info: union(enum) {
            fill: struct { block: Block },
            generate: struct { pos: @Vector(2, u32), seed: i32 },
        },
    ) Allocator.Error!*Self {
        const result = try allocator.create(Chunk);
        switch (info) {
            .fill => |fill| @memset(result.blocks[0..], fill.block),
            .generate => |generate| {
                const value_gen = Noise{
                    .seed = generate.seed,
                    .noise_type = .value,
                };

                const cellular_gen = Noise{
                    .seed = generate.seed,
                    .noise_type = .cellular,
                };

                var z: u32 = 0;
                while (z < h) : (z += 1) {
                    var y: u32 = 0;
                    while (y < w) : (y += 1) {
                        var x: u32 = 0;
                        while (x < w) : (x += 1) {
                            const xf = @as(f32, @floatFromInt(x + generate.pos[0] * w));
                            const yf = @as(f32, @floatFromInt(y + generate.pos[1] * w));
                            const zf = @as(f32, @floatFromInt(z));

                            const noise_stone: f32 = value_gen.noise2(
                                xf * 5,
                                yf * 5,
                            ) * 12 + cellular_gen.noise2(
                                xf * 5,
                                yf * 5,
                            ) * 12 + 25;

                            const noise_dirt: f32 = value_gen.noise2(
                                xf * 5,
                                yf * 5,
                            ) * 3 + cellular_gen.noise2(
                                xf * 3,
                                yf * 3,
                            ) * 2 + 20;

                            const noise_sand: f32 = cellular_gen.noise2(
                                xf * 6,
                                yf * 6,
                            ) * 3 + cellular_gen.noise2(
                                xf * 9,
                                yf * 9,
                            ) * 3 + 23;

                            const block: Block = if (zf < noise_stone)
                                .stone
                            else if (zf < noise_dirt)
                                .dirt
                            else if (zf < noise_sand)
                                .sand
                            else
                                .air;

                            result.setBlock(.{ x, y, z }, block);
                        }
                    }
                }
            },
        }
        return result;
    }

    pub fn destroy(self: *Self, allocator: Allocator) void {
        allocator.destroy(self);
    }

    pub inline fn getBlock(self: *Self, pos: @Vector(3, u32)) Block {
        return self.blocks[pos[0] + pos[1] * w + pos[2] * w * w];
    }

    pub inline fn setBlock(self: *Self, pos: @Vector(3, u32), block: Block) void {
        self.blocks[pos[0] + pos[1] * w + pos[2] * w * w] = block;
    }
};

pub const Map = struct {
    pub const w = 512;
    pub const v = w * w;
    pub const s = @Vector(2, u32){ w, w };

    pub const Config = struct {
        seed: i32 = 6969,
    };

    const Self = @This();

    chunks: [v]*Chunk,
    zero: *Chunk,
    config: Config,
    allocator: Allocator,

    pub fn create(allocator: Allocator, config: Config) Allocator.Error!*Self {
        var result: *Self = try allocator.create(Self);

        result.allocator = allocator;
        result.config = config;
        result.zero = try Chunk.create(allocator, .{ .fill = .{ .block = .air } });
        @memset(result.chunks[0..], result.zero);

        return result;
    }

    pub fn destroy(self: *Self) void {
        for (self.chunks[0..]) |chunk|
            if (chunk != self.zero) chunk.destroy(self.allocator);

        self.zero.destroy(self.allocator);
    }

    pub fn generate(self: *Self) Allocator.Error!void {
        var y: u32 = 0;
        while (y < 8) : (y += 1) {
            var x: u32 = 0;
            while (x < 8) : (x += 1) {
                self.setChunk(.{ x, y }, try Chunk.create(self.allocator, .{
                    .generate = .{
                        .pos = .{ x, y },
                        .seed = self.config.seed,
                    },
                }));
            }
        }
    }

    pub inline fn getChunk(self: *Self, pos: @Vector(2, u32)) *Chunk {
        return self.chunks[pos[0] + pos[1] * w];
    }

    pub inline fn setChunk(self: *Self, pos: @Vector(2, u32), chunk: *Chunk) void {
        self.chunks[pos[0] + pos[1] * w] = chunk;
    }

    pub inline fn getBlock(self: *Self, pos: @Vector(3, u32)) Block {
        return self.getChunk(.{ pos[0] / Chunk.w, pos[1] / Chunk.w }).getBlock(pos % Chunk.s);
    }

    pub inline fn setBlock(self: *Self, pos: @Vector(3, u32), block: Block) void {
        self.getChunk(.{ pos[0] / Chunk.w, pos[1] / Chunk.w }).setBlock(pos % Chunk.s, block);
    }
};

pub const Drawer = struct {
    const Self = @This();

    camera: *Camera,
    map: *Map,

    chunks: struct {
        meshes: [Map.v]?*gfx.Mesh = [1]?*gfx.Mesh{null} ** Map.v,
        buffers: struct {
            vertex: [Map.v]*gfx.Buffer,
            normal: [Map.v]*gfx.Buffer,
        },
    },

    pub fn create(
        allocator: Allocator,
        info: struct {
            camera: *Camera,
            map: *Map,
        },
    ) Allocator.Error!*Self {
        const result = try allocator.create(Self);

        result.camera = info.camera;
        result.map = info.map;

        return result;
    }

    pub fn draw() !void {}

    pub fn destroy() void {}
};
