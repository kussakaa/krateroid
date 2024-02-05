const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");
const Menu = @import("Menu.zig");

data: []const u16,
rect: Rect,
alignment: Alignment,
usage: Usage,
menu: *const Menu,

pub const Usage = enum { static, dynamic };
