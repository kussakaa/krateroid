const Menu = @import("Menu.zig");
const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

menu: *const Menu,
data: []const u16,
rect: Rect,
alignment: Alignment,
