const std = @import("std");
const Allocator = std.mem.Allocator;

const Rect = @import("Gui/Rect.zig");
const Alignment = @import("Gui/Alignment.zig");
const Font = @import("Gui/Font.zig");

const Text = @import("Gui/Text.zig");
const Button = @import("Gui/Button.zig");

const Point = @Vector(2, i32);
const Color = @Vector(4, f32);

const Gui = @This();

pub const Control = union(enum) {
    text: Text,
    button: Button,
};

controls: std.ArrayList(Control),
font: Font,

pub const InitInfo = struct {
    allocator: Allocator,
};

pub fn init(info: InitInfo) !Gui {
    return Gui{
        .controls = std.ArrayList(Control).init(info.allocator),
        .font = Font.init(),
    };
}

pub fn deinit(self: Gui) void {
    self.controls.deinit();
}
