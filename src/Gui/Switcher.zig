const Menu = @import("Menu.zig");
const Pos = @Vector(2, i32);
const Alignment = @import("Alignment.zig");

pub const Id = usize;
const Self = @This();

menu: Menu.Id,
id: Self.Id,
pos: Pos,
alignment: Alignment,
status: bool,
state: enum(u8) { empty, focus, press } = .empty,
