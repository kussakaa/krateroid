const Vec3 = @import("linmath.zig").F32x3;

pub const Quad = struct {
    pos: Vec3 = Vec3{ 0.0, 0.0, 0.0 },
    size: Vec3 = Vec3{ 1.0, 1.0, 1.0 },
};
