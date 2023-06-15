const I32x2 = @import("linmath.zig").I32x2;

pub const Event = union(enum) {
    quit,
    key_down: i32,
    key_up: i32,
    mouse_button_down: i32,
    mouse_button_up: i32,
    mouse_motion: I32x2,
    window_size: I32x2,
    none,
};
