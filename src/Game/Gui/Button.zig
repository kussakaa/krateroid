const Gui = @import("../Gui.zig");

const Rect = @import("Rect.zig");
const Alignment = @import("Alignment.zig");

const Text = @import("Text.zig");

pub const State = enum {
    empty,
    focus,
    press,

    pub const count = 3;
};

const Button = @This();
rect: Rect,
alignment: Alignment,
state: enum(u8) { empty, focus, press } = .empty,
text: Text,

pub const InitInfo = struct {
    rect: Rect,
    alignment: Alignment = .{},
    text: []const u16 = &.{'-'},
};

pub fn init(gui: Gui, info: InitInfo) !Button {
    return .{
        .rect = info.rect,
        .alignment = info.alignment,
        .text = try Text.init(gui, .{
            .data = info.text,
            .pos = info.rect.min,
            .alignment = info.alignment,
        }),
    };
}
