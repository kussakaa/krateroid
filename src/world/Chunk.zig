pub const Pos = @Vector(2, u32);
pub const H = u8;
pub const M = u8;
pub const HMap = [width][width]H;
pub const MMap = [width][width]M;
pub const width = 32;
hmap: HMap,
mmap: MMap,
