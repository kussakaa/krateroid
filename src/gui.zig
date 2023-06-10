const linmath = @import("linmath.zig");

pub const Point = linmath.I32x2;
pub const Line = linmath.I32x2;
pub const Rect = linmath.I32x4;
pub const Button = struct {
    rect: Rect,
};

pub fn alignRect(rect: Rect, alignment: Alignment, vpsize: linmath.I32x2) Rect {
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
    buttons: @Vector(0, Button),

    pub fn addButton(self: Gui, button: Button) void {
        self.buttons ++ button;
    }

    //pub fn pushEvent(self: Gui) void {}
};
