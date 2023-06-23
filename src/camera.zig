const linmath = @import("linmath.zig");
const Vec = linmath.Vec;
const Mat = linmath.Mat;

pub const Camera = struct {
    pos: Vec = Vec{ 0.0, 0.0, 0.0, 1.0 },
    rot: Vec = Vec{ 0.0, 0.0, 0.0, 1.0 },
    scale: Vec = Vec{ 1.0, 1.0, 1.0, 1.0 },

    model: Mat = linmath.MatIdentity,
    view: Mat = linmath.MatIdentity,
    proj: Mat = linmath.MatIdentity,
};
