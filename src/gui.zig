const std = @import("std");
const Event = @import("events.zig").Event;

pub const I32x2 = @import("linmath.zig").I32x2;
pub const I32x4 = @import("linmath.zig").I32x4;
pub const Point = I32x2;
pub const Line = I32x2;
pub const Rect = I32x4;
pub const Button = struct {
    rect: Rect = Rect{ 0, 0, 100, 50 },
    state: State = State.Normal,
    alignment: Alignment = Alignment.left_bottom,

    pub const State = enum {
        Normal,
        Focused,
        Pushed,
    };
};

pub fn rectAlignOfVp(rect: Rect, alignment: Alignment, vpsize: I32x2) Rect {
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
    vpsize: I32x2,
    mouse: struct {
        click: bool,
        pos: I32x2,
    },
    buttons: std.ArrayList(Button),

    pub fn init() Gui {
        return Gui{
            .enable = true,
            .vpsize = I32x2{ 800, 600 },
            .mouse = .{
                .click = false,
                .pos = I32x2{ 0, 0 },
            },
            .buttons = std.ArrayList(Button).init(std.heap.page_allocator),
        };
    }

    pub fn addButton(self: *Gui, button: Button) !void {
        try self.buttons.append(button);
    }

    pub fn pollEvent(self: *Gui, event: Event) GuiEvent {
        if (self.enable) {
            switch (event) {
                Event.mouse_motion => |pos| {
                    self.mouse.pos = I32x2{ pos[0], self.vpsize[1] - pos[1] };
                    for (self.buttons.items) |*button| {
                        if (rectIsAround(rectAlignOfVp(button.rect, button.alignment, self.vpsize), self.mouse.pos)) {
                            if (self.mouse.click) {
                                button.state = Button.State.Pushed;
                            } else {
                                button.state = Button.State.Focused;
                            }
                        } else {
                            button.state = Button.State.Normal;
                        }
                    }
                    return GuiEvent.none;
                },
                Event.mouse_button_down => |key| {
                    if (key == 1) {
                        self.mouse.click = true;
                        for (self.buttons.items) |*button, i| {
                            if (button.state == Button.State.Focused) {
                                button.state = Button.State.Pushed;
                                return GuiEvent{ .button_down = @intCast(i32, i) };
                            }
                        }
                    }
                },
                Event.mouse_button_up => |key| {
                    if (key == 1) {
                        self.mouse.click = false;
                        for (self.buttons.items) |*button, i| {
                            if (button.state == Button.State.Pushed) {
                                button.state = Button.State.Focused;
                                return GuiEvent{ .button_up = @intCast(i32, i) };
                            }
                        }
                    }
                },
                Event.window_size => |size| {
                    self.vpsize = size;
                },
                else => {},
            }
        }
        return GuiEvent.none;
    }
};

pub const GuiEvent = union(enum) {
    button_down: i32,
    button_up: i32,
    none,
};
