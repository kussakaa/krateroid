const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

data: []const u16,
rect: Rect,
alignment: Alignment,
usage: Usage,

pub const Usage = enum { static, dynamic };
