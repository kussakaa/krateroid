const Menu = @import("Mqnu.zig");
const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

menu: *const Menu,
rect: Rect,
alignment: Alignment,
steps: u32,
value: u32,
