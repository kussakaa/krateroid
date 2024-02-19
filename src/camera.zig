const std = @import("std");
const log = std.log.scoped(.camera);

const window = @import("window.zig");

const zm = @import("zmath");
const vec = zm.f32x4;
const Vec = zm.Vec;
const Mat = zm.Mat;

pub const forward = vec(0.0, 1.0, 0.0, 0.0);
pub const up = vec(0.0, 0.0, 1.0, 0.0);
pub const right = vec(1.0, 0.0, 0.0, 0.0);

pub var pos = vec(0.0, 0.0, 0.0, 0.0);
pub var rot = vec(0.0, 0.0, 0.0, 0.0);
pub var scale: f32 = 1.0;

pub var view = zm.identity();
pub var proj = zm.identity();

pub fn update() void {
    view = zm.identity();
    view = zm.mul(view, zm.translationV(-pos));
    view = zm.mul(view, zm.rotationZ(rot[2]));
    view = zm.mul(view, zm.rotationX(rot[0]));
    const h = 1.0 / scale;
    const v = 1.0 / scale / window.ratio;
    proj = Mat{
        .{ v, 0.0, 0.0, 0.0 },
        .{ 0.0, h, 0.0, 0.0 },
        .{ 0.0, 0.0, -0.00001, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}
