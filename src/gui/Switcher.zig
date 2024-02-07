const Menu = @import("Mqnu.zig");
const Pos = @Vector(2, i32);
const Alignment = @import("Alignment.zig");

menu: *const Menu,
pos: Pos,
alignment: Alignment,
status: bool,
