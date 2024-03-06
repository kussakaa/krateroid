pub const Pos = @Vector(3, u32);
pub const Block = bool;
pub const Grid = [width][width][width]Block;
pub const width = 32;
grid: Grid,
