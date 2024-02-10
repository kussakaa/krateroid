const Menu = @import("Menu.zig");
const Pos = @Vector(2, i32);
const Alignment = @import("Alignment.zig");

menu: *const Menu,
id: u32,
pos: Pos,
alignment: Alignment,
status: bool,
state: enum(u8) { empty, focus, press } = .empty,
