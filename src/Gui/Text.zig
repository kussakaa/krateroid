const Menu = @import("Menu.zig");
const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

pub const Id = usize;
const Self = @This();

menu: Menu.Id,
id: Self.Id,
data: []const u16,
rect: Rect,
alignment: Alignment,
