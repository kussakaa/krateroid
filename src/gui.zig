const std = @import("std");
const Allocator = std.mem.Allocator;

const Event = @import("events.zig").Event;

pub const I32x2 = @import("linmath.zig").I32x2;
pub const I32x4 = @import("linmath.zig").I32x4;
pub const Point = I32x2;
pub const Line = I32x2;
pub const Rect = I32x4;
pub const Text = struct {
    data: []const u16,
    pos: I32x2 = I32x2{ 0, 0 },
    alignment: Alignment = Alignment.left_bottom,
};

pub const Button = struct {
    rect: Rect = Rect{ 0, 0, 100, 50 },
    state: State = State.Normal,
    alignment: Alignment = Alignment.left_bottom,
    text: Text,

    pub const State = enum {
        Normal,
        Focused,
        Pushed,
    };

    pub fn init(rect: Rect, alignment: Alignment, title: []const u16) Button {
        return Button{
            .rect = rect,
            .alignment = alignment,
            .text = Text{
                .data = title,
                .pos = I32x2{
                    rect[0] + @divTrunc(rect[2] - rect[0], 2) - @intCast(i32, title.len) * 7,
                    rect[1] + @divTrunc(rect[3] - rect[1], 2) - 8,
                },
                .alignment = alignment,
            },
        };
    }
};

pub fn pointAlignOfVp(point: Point, alignment: Alignment, vpsize: I32x2) Point {
    return switch (alignment) {
        Alignment.left_bottom => point,
        Alignment.right_bottom => point + Point{ vpsize[0], 0 },
        Alignment.right_top => point + vpsize,
        Alignment.left_top => point + Point{ 0, vpsize[1] },
        Alignment.center_bottom => point + Point{ @divTrunc(vpsize[0], 2), 0 },
        Alignment.right_center => point + Point{ vpsize[0], @divTrunc(vpsize[1], 2) },
        Alignment.center_top => point + Point{ @divTrunc(vpsize[0], 2), vpsize[1] },
        Alignment.left_center => point + Point{ 0, @divTrunc(vpsize[1], 2) },
        Alignment.center_center => point + Point{ @divTrunc(vpsize[0], 2), @divTrunc(vpsize[1], 2) },
    };
}

pub fn rectAlignOfVp(rect: Rect, alignment: Alignment, vpsize: I32x2) Rect {
    return switch (alignment) {
        Alignment.left_bottom => rect,
        Alignment.right_bottom => rect + [4]i32{ vpsize[0], 0, vpsize[1], 0 },
        Alignment.right_top => rect + [4]i32{ vpsize[0], vpsize[1], vpsize[0], vpsize[1] },
        Alignment.left_top => rect + [4]i32{ 0, vpsize[1], 0, vpsize[1] },
        Alignment.center_bottom => rect + [4]i32{ @divTrunc(vpsize[0], 2), 0, @divTrunc(vpsize[0], 2), 0 },
        Alignment.right_center => rect + [4]i32{
            vpsize[0],
            @divTrunc(vpsize[1], 2),
            vpsize[0],
            @divTrunc(vpsize[1], 2),
        },
        Alignment.center_top => rect + [4]i32{
            @divTrunc(vpsize[0], 2),
            vpsize[1],
            @divTrunc(vpsize[0], 2),
            vpsize[1],
        },
        Alignment.left_center => rect + [4]i32{ 0, @divTrunc(vpsize[1], 2), 0, @divTrunc(vpsize[1], 2) },
        Alignment.center_center => rect + [4]i32{
            @divTrunc(vpsize[0], 2),
            @divTrunc(vpsize[1], 2),
            @divTrunc(vpsize[0], 2),
            @divTrunc(vpsize[1], 2),
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
    enable: bool = true,
    vpsize: I32x2 = .{ 1200, 900 },
    mouse: struct {
        click: bool = false,
        pos: I32x2 = I32x2{ 0, 0 },
    },
    buttons: std.ArrayList(Button),

    pub fn init(allocator: Allocator) Gui {
        return Gui{
            .mouse = .{},
            .buttons = std.ArrayList(Button).init(allocator),
        };
    }

    pub fn addButton(self: *Gui, button: Button) !void {
        try self.buttons.append(button);
    }

    pub fn pollEvent(self: *Gui, event: Event) GuiEvent {
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
            },
            Event.mouse_button_down => |key| {
                if (self.enable and key == 1) {
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
                if (self.enable and key == 1) {
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
        return GuiEvent.none;
    }

    pub fn deinit(self: Gui) void {
        _ = self;
    }
};

pub const GuiEvent = union(enum) {
    button_down: i32,
    button_up: i32,
    none,
};
