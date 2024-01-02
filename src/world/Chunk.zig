pub const Pos = @Vector(2, u32);
pub const Block = u8;
pub const Data = [width][width][width]Block;
pub const width = 32;
blocks: Data,
