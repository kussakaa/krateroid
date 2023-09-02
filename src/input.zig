pub const Event = union(enum) {
    quit,
    key_down: i32,
    key_up: i32,
    mouse_button_down: MouseButton,
    mouse_button_up: MouseButton,
    mouse_motion: @Vector(2, i32),
    window_size: @Vector(2, i32),
    none,
};

pub const MouseButton = enum(u8) {
    empty,
    left,
    middle,
    right,
    _,
};
