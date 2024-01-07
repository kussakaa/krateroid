const lm = @import("linmath.zig");
const Vec = lm.Vec;
const Mat = lm.Mat;

pub var pos = lm.zero(Vec(3));
pub var rot = lm.zero(Vec(3));

pub var view = lm.identity(Mat(4));
pub var proj = lm.identity(Mat(4));
