h: H = 0,
m: M = .empty,

pub const H = u8;
pub const M = enum(u8) {
    empty = 0,
    dirt,
    sand,
    stone,
};
