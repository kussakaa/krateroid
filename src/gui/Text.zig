const Menu = @import("Menu.zig");
const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

pub const Usage = enum { static, dynamic };

menu: *const Menu,
data: []const u16,
rect: Rect,
alignment: Alignment,
usage: Usage,
