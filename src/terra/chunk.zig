pub const Id = usize;

pub const width = 32;

pub const Block = enum(u8) {
    pub const Id = usize;

    air = 0,
    stone = 1,
    dirt = 2,
    sand = 3,
};
