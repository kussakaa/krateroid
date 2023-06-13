const std = @import("std");
const linmath = @import("linmath.zig");
const Event = @import("events.zig").Event;
const EventTag = @import("events.zig").EventTag;

pub const Point = linmath.I32x2;
pub const Line = linmath.I32x2;
pub const Rect = linmath.I32x4;
pub const Button = struct {
    rect: Rect,
    state: State,
    alignment: Alignment,

    pub const State = enum {
        Disabled,
        Focused,
        Pushed,
        Unpushed,
    };
};

pub fn rectAlignOfVp(rect: Rect, alignment: Alignment, vpsize: linmath.I32x2) Rect {
    return switch (alignment) {
        Alignment.left_bottom => rect,
        Alignment.right_bottom => Rect{
            vpsize[0] - rect[2],
            rect[1],
            vpsize[0] - rect[0],
            rect[3],
        },
        Alignment.right_top => Rect{
            vpsize[0] - rect[2],
            vpsize[1] - rect[3],
            vpsize[0] - rect[0],
            vpsize[1] - rect[1],
        },
        Alignment.left_top => Rect{
            rect[0],
            vpsize[1] - rect[3],
            rect[2],
            vpsize[1] - rect[1],
        },
        Alignment.center_bottom => Rect{
            @divTrunc(vpsize[0], 2) + rect[0],
            rect[1],
            @divTrunc(vpsize[0], 2) + rect[2],
            rect[3],
        },
        Alignment.right_center => Rect{
            vpsize[0] - rect[2],
            @divTrunc(vpsize[1], 2) + rect[1],
            vpsize[0] - rect[0],
            @divTrunc(vpsize[1], 2) + rect[3],
        },
        Alignment.center_top => Rect{
            @divTrunc(vpsize[0], 2) + rect[0],
            vpsize[1] - rect[3],
            @divTrunc(vpsize[0], 2) + rect[2],
            vpsize[1] - rect[1],
        },
        Alignment.left_center => Rect{
            rect[0],
            @divTrunc(vpsize[1], 2) + rect[1],
            rect[2],
            @divTrunc(vpsize[1], 2) + rect[3],
        },
        Alignment.center_center => Rect{
            @divTrunc(vpsize[0], 2) + rect[0],
            @divTrunc(vpsize[1], 2) + rect[1],
            @divTrunc(vpsize[0], 2) + rect[2],
            @divTrunc(vpsize[1], 2) + rect[3],
        },
    };
}

pub fn rectIsAround(rect: Rect, point: Point) bool {
    if (point[0] > rect[0] and point[0] < rect[2] and point[1] > rect[1] and point[1] < rect[3]) return true;
    return false;
}

pub const Alignment = enum {
    left_bottom, // стандарт
    right_bottom,
    right_top,
    left_top,
    center_bottom,
    right_center,
    center_top,
    left_center,
    center_center,
};

pub const Gui = struct {
    enable: bool,
    vpsize: linmath.I32x2,
    buttons: std.ArrayList(Button),

    pub fn init() Gui {
        return Gui{
            .enable = true,
            .vpsize = linmath.I32x2{ 800, 600 },
            .buttons = std.ArrayList(Button).init(std.heap.page_allocator),
        };
    }

    pub fn addButton(self: *Gui, button: Button) !void {
        try self.buttons.append(button);
    }

    pub fn pushEvent(self: *Gui, event: Event) void {
        if (self.enable) {
            switch (event) {
                Event.press => |key| {
                    _ = key;
                },
                Event.unpress => |key| {
                    _ = key;
                },
                Event.click => |key| {
                    if (key == 0) {
                        for (self.buttons.items) |*button| {
                            if (button.state == Button.State.Focused) {
                                button.state = Button.State.Pushed;
                            }
                        }
                    }
                },
                Event.unclick => |key| {
                    if (key == 0) {
                        for (self.buttons.items) |*button| {
                            if (button.state == Button.State.Focused) {
                                button.state = Button.State.Unpushed;
                            }
                        }
                    }
                },
                Event.size => |size| {
                    self.vpsize = size;
                },
                Event.pos => |pos| {
                    for (self.buttons.items) |*button| {
                        if (rectIsAround(rectAlignOfVp(button.rect, button.alignment, self.vpsize), pos)) {
                            button.state = Button.State.Focused;
                        } else {
                            button.state = Button.State.Disabled;
                        }
                    }
                },
            }
        }
    }
};
