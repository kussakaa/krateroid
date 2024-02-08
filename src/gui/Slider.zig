const Menu = @import("Menu.zig");
const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

menu: *const Menu,
id: u32,
rect: Rect,
alignment: Alignment,
steps: i32,
value: f32,
state: enum(u8) { empty, focus, press } = .empty,
