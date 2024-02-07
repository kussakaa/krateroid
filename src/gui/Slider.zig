const Menu = @import("Menu.zig");
const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

menu: *const Menu,
id: u32,
rect: Rect,
alignment: Alignment,
steps: i32,
value: i32,
