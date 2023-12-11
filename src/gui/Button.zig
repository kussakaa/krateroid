const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

rect: Rect,
alignment: Alignment,
state: enum(u8) { empty, focus, press } = .empty,
enable: bool = true,
