const I32x2 = @import("linmath.zig").I32x2;

pub const Event = union(enum) {
    press: i32,
    unpress: i32,
    click: i32,
    unclick: i32,
    pos: I32x2,
    size: I32x2,
};
