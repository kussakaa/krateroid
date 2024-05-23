pub const width = 32;
pub const Pos = @Vector(3, u32);

pub const Material = enum(u8) {
    air = 0,
    stone = 1,
    dirt = 2,
    sand = 3,
};

material: Material = .air,
