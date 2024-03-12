const Vec = @import("zmath").Vec;
const Color = Vec;

pub const Id = usize;
const Self = @This();

id: Self.Id,
p1: Vec,
p2: Vec,
color: Color,
show: bool,
