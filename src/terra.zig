const std = @import("std");
const log = std.log.scoped(.terra);

const Allocator = std.mem.Allocator;

const znoise = @import("znoise");
const Noise = znoise.FnlGenerator;

pub const Seed = i32;

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

    data: [v]Block,

    pub fn create(
        allocator: Allocator,
        info: union(enum) {
            fill: struct { block: Block },
            generate: struct { pos: @Vector(2, u32), seed: Seed },
        },
    ) !*Chunk {
        const result = try allocator.create(Chunk);
        switch (info) {
            .fill => |fill| @memset(result.data[0..], fill.block),
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

                            result.set(.{ x, y, z }, block);
                        }
                    }
                }
            },
        }
        return result;
    }

    pub fn destroy(self: *Chunk, allocator: Allocator) void {
        allocator.destroy(self);
    }

    pub inline fn get(self: *Chunk, pos: @Vector(3, u32)) Block {
        return self.data[pos[0] + pos[1] * w + pos[2] * w * w];
    }

    pub inline fn set(self: *Chunk, pos: @Vector(3, u32), block: Block) void {
        self.data[pos[0] + pos[1] * w + pos[2] * w * w] = block;
    }
};

pub const Chunks = struct {
    pub const w = 512;
    pub const v = w * w;
    pub const s = @Vector(2, u32){ w, w };

    data: [v]*Chunk,
    null_chunk: *Chunk,
    seed: Seed,
    allocator: Allocator,

    pub fn init(allocator: Allocator, seed: Seed) !Chunks {
        var result: Chunks = undefined;

        result.null_chunk = try Chunk.create(allocator, .{ .fill = .{ .block = .air } });
        @memset(result.data[0..], result.null_chunk);
        result.seed = seed;
        result.allocator = allocator;

        return result;
    }

    pub fn deinit(self: *Chunks) void {
        var y: u32 = 0;
        while (y < 8) : (y += 1) {
            var x: u32 = 0;
            while (x < 8) : (x += 1) {
                const chunk = self.get(.{ x, y });
                if (chunk != self.null_chunk) chunk.destroy(self.allocator);
            }
        }
        self.null_chunk.destroy(self.allocator);
    }

    pub inline fn get(self: *Chunks, pos: @Vector(2, u32)) *Chunk {
        return self.data[pos[0] + pos[1] * w];
    }

    pub inline fn set(self: *Chunks, pos: @Vector(2, u32), chunk: *Chunk) void {
        self.data[pos[0] + pos[1] * w] = chunk;
    }
};

pub var chunks: Chunks = undefined;

pub fn init(allocator: Allocator, seed: Seed) !void {
    log.info("init", .{});

    chunks = try Chunks.init(allocator, seed);

    var y: u32 = 0;
    while (y < 8) : (y += 1) {
        var x: u32 = 0;
        while (x < 8) : (x += 1) {
            chunks.set(.{ x, y }, try Chunk.create(
                allocator,
                .{ .generate = .{ .pos = .{ x, y }, .seed = chunks.seed } },
            ));
        }
    }

    log.info("init succes", .{});
}

pub fn deinit() void {
    chunks.deinit();
}

pub inline fn getBlock(pos: @Vector(3, u32)) Block {
    return chunks.get(.{ pos[0] / Chunk.w, pos[1] / Chunk.w }).get(pos % Chunk.s);
}
