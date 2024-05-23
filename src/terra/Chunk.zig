const Noise = @import("znoise").FnlGenerator;

pub const Seed = i32;
pub const Pos = @Vector(3, u32);

pub const width = 32;
pub const Size = @Vector(3, u32);
pub const size = Size{ width, width, width };
pub const volume = width * width * width;

const Block = @import("Block.zig");
const Blocks = [volume]Block;
blocks: Blocks,

const Self = @This();

pub const InitInfo = union(enum) {
    fill: struct { block: Block },
    load,
    generate: struct { seed: Seed },
};

pub fn init(pos: Pos, info: InitInfo) Self {
    var result: Self = undefined;

    switch (info) {
        .fill => {
            result.fill(info.fill.block);
        },
        .load => {
            result.fill(.{ .material = .air });
        },
        .generate => {
            const value_gen = Noise{
                .seed = info.generate.seed,
                .noise_type = .value,
            };

            const cellular_gen = Noise{
                .seed = info.generate.seed,
                .noise_type = .cellular,
            };

            var z: u32 = 0;
            while (z < width) : (z += 1) {
                var y: u32 = 0;
                while (y < width) : (y += 1) {
                    var x: u32 = 0;
                    while (x < width) : (x += 1) {
                        const xf = @as(f32, @floatFromInt(x + pos[0] * width));
                        const yf = @as(f32, @floatFromInt(y + pos[1] * width));
                        //                const zf = @as(f32, @floatFromInt(z + pos[2] * chunk.width));

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

                        const blockzf = @as(f32, @floatFromInt(z + pos[2] * width));
                        const block: Block = .{
                            .material = if (blockzf < noise_stone)
                                .stone
                            else if (blockzf < noise_dirt)
                                .dirt
                            else if (blockzf < noise_sand)
                                .sand
                            else
                                .air,
                        };

                        result.set(.{ x, y, z }, block);
                    }
                }
            }
        },
    }

    return result;
}

pub inline fn fill(self: *Self, block: Block) void {
    @memset(self.blocks[0..], block);
}

pub inline fn get(self: Self, pos: Block.Pos) Block {
    return self.blocks[pos[0] + pos[1] * width + pos[2] * width * width];
}

pub inline fn set(self: *Self, pos: Block.Pos, block: Block) void {
    self.blocks[pos[0] + pos[1] * width + pos[2] * width * width] = block;
}
