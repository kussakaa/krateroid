pub const Chunk = struct {
    const WIDTH = 8;
    const VOLUME = WIDTH * WIDTH * WIDTH;

    data: [VOLUME]u8 = [1]u8{0} ** VOLUME,

    pub fn init() Chunk {
        var chunk = Chunk{};

        var z = 0;
        while (z < WIDTH) : (z += 1) {
            var y = 0;
            while (y < WIDTH) : (y += 1) {
                var x = 0;
                while (x < WIDTH) : (x += 1) {
                    if (z < 4) {
                        chunk.data[z * WIDTH * WIDTH + y * WIDTH + x] = 1;
                    }
                }
            }
        }

        return chunk;
    }
};
