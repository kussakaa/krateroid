const std = @import("std");
const I32x2 = @import("linmath.zig").I32x2;

pub const Chunk = struct {
    pub const width = 32;
    pub const volume = width * width * width;

    pos: I32x2 = .{ 0, 0 },
    edit: u32 = 0,
    blocks: [volume]u8 = [1]u8{0} ** volume,

    pub fn init(pos: I32x2) Chunk {
        var chunk = Chunk{};
        chunk.pos = pos;

        var z: usize = 0;
        while (z < width) : (z += 1) {
            var y: usize = 0;
            while (y < width) : (y += 1) {
                var x: usize = 0;
                while (x < width) : (x += 1) {
                    if (@intToFloat(f32, z) < 4 +
                        @sin((@intToFloat(f32, x) + @intToFloat(f32, pos[0])) * 0.2) * 2.0 +
                        @sin((@intToFloat(f32, y) + @intToFloat(f32, pos[1])) * 0.2) * 2.0)
                    {
                        chunk.blocks[z * width * width + y * width + x] = 1;
                    }
                }
            }
        }

        return chunk;
    }
};

pub const World = struct {
    seed: u32,
    chunks: std.ArrayList(Chunk),

    pub fn init(seed: u32) World {
        return World{
            .seed = seed,
            .chunks = std.ArrayList(Chunk).init(std.heap.page_allocator),
        };
    }

    pub fn add_chunk(self: *World, pos: I32x2) !void {
        for (self.chunks.items) |chunk| {
            if (chunk.pos[0] == pos[0] and chunk.pos[1] == pos[1]) return;
        }

        try self.chunks.append(Chunk.init(pos));
    }
};
