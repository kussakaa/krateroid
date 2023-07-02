const linmath = @import("linmath.zig");
const Vec3 = linmath.F32x4;
const Mat = linmath.Mat;

pub const Camera = struct {
    pos: Vec3 = Vec3{ 0.0, 0.0, 0.0, 1.0 },
    rot: Vec3 = Vec3{ 0.0, 0.0, 0.0, 1.0 },
    scale: Vec3 = Vec3{ 1.0, 1.0, 1.0, 1.0 },

    model: Mat = linmath.MatIdentity,
    view: Mat = linmath.MatIdentity,
    proj: Mat = linmath.MatIdentity,
};
