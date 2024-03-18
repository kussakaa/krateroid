pub const Pos = @Vector(2, usize);
pub const Block = bool;
pub const Blocks = [width][width][width]Block;
pub const width = 32;
blocks: Blocks,
