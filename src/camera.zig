const linmath = @import("linmath.zig");
const Vec3 = linmath.F32x3;
const Mat = linmath.Mat;

pub const Camera = struct {
    pos: Vec3 = Vec3{ 0.0, 0.0, 0.0 },
    rot: Vec3 = Vec3{ 0.0, 0.0, 0.0 },
    scale: Vec3 = Vec3{ 1.0, 1.0, 1.0 },

    view: Mat = linmath.MatIdentity,
    proj: Mat = linmath.MatIdentity,
};
