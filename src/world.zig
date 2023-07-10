const I32x2 = @import("linmath.zig").I32x2;

pub const Chunk = struct {
    pub const width = 32;
    pub const volume = width * width * width;

    pos: I32x2 = .{ 0, 0 },
    data: [volume]u8 = [1]u8{0} ** volume,
    edit: u32 = 0,

    pub fn init() Chunk {
        var chunk = Chunk{};

        var z: usize = 0;
        while (z < width) : (z += 1) {
            var y: usize = 0;
            while (y < width) : (y += 1) {
                var x: usize = 0;
                while (x < width) : (x += 1) {
                    if (@intToFloat(f32, z) < 4 + @sin(@intToFloat(f32, x) * 0.5) * 2.0 + @sin(@intToFloat(f32, y) * 0.5) * 2.0) {
                        chunk.data[z * width * width + y * width + x] = 1;
                    }
                }
            }
        }

        return chunk;
    }
};
