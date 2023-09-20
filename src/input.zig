pub const Point = @Vector(2, i32);

pub const Event = union(enum) {
    quit,
    key_down: i32,
    key_up: i32,
    mouse_button_down: MouseButton,
    mouse_button_up: MouseButton,
    mouse_motion: Point,
    window_size: Point,
    none,
};

pub const State = struct {
    frame: u32 = 0,
    keyboard: struct {
        keys: [1024]struct {
            press: bool = false,
            frame: u32 = 0,
        },
    },
    mouse: struct {
        buttons: [9]struct {
            click: bool = false,
            frame: u32 = 0,
        },
    },
    cursor: struct {
        pos: Point,
    },
};
