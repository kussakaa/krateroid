const Menu = @import("Menu.zig");
const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

pub const Id = usize;
const Self = @This();

menu: Menu.Id,
id: Self.Id,
rect: Rect,
alignment: Alignment,
steps: i32,
value: f32,
state: enum(u8) { empty, focus, press } = .empty,
