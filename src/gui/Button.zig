const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");
const Menu = @import("Menu.zig");

id: u32,
rect: Rect,
alignment: Alignment,
state: enum(u8) { empty, focus, press } = .empty,
menu: *const Menu,
