const std = @import("std");
const log = std.log.scoped(.camera);

const lm = @import("linmath.zig");
const Vec = lm.Vec;
const Mat = lm.Mat;

pub var pos = lm.zero(Vec);
pub var rot = lm.zero(Vec);

pub var view = lm.identity(Mat);
pub var proj = lm.identity(Mat);
