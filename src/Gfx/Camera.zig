pos: zm.Vec,
rot: zm.Vec,
scale: f32,
ratio: f32,
view: zm.Mat,
proj: zm.Mat,

pub const right = zm.f32x4(1.0, 0.0, 0.0, 0.0);
pub const left = zm.f32x4(-1.0, 0.0, 0.0, 0.0);
pub const forward = zm.f32x4(0.0, 1.0, 0.0, 0.0);
pub const back = zm.f32x4(0.0, -1.0, 0.0, 0.0);
pub const up = zm.f32x4(0.0, 0.0, 1.0, 0.0);
pub const down = zm.f32x4(0.0, 0.0, -1.0, 0.0);

pub const Config = struct {
    pos: zm.Vec = .{ 0.0, 0.0, 0.0, 1.0 },
    rot: zm.Vec = .{ 0.0, 0.0, 0.0, 1.0 },
    scale: f32 = 1.0,
    ratio: f32 = 1.0,
};

pub fn init(config: Config) Camera {
    log.info("Initialization", .{});

    var result = Camera{
        .pos = config.pos,
        .rot = config.rot,
        .scale = config.scale,
        .ratio = config.ratio,
        .view = zm.identity(),
        .proj = zm.identity(),
    };

    result.update();

    log.info("Initialization {s}{s}competed{s}", .{
        TermColor(null).bold(),
        TermColor(.fg).bit(2),
        TermColor(null).reset(),
    });

    return result;
}

pub fn deinit(self: *Camera) void {
    self.* = undefined;
}

pub fn update(self: *Camera) void {
    self.view = zm.identity();
    self.view = zm.mul(self.view, zm.translationV(-self.pos));
    self.view = zm.mul(self.view, zm.rotationZ(self.rot[2]));
    self.view = zm.mul(self.view, zm.rotationX(self.rot[0]));
    const h = 1.0 / self.scale;
    const v = 1.0 / self.scale / self.ratio;
    self.proj = zm.Mat{
        .{ v, 0.0, 0.0, 0.0 },
        .{ 0.0, h, 0.0, 0.0 },
        .{ 0.0, 0.0, -0.00001, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

const Camera = @This();
const zm = @import("zmath");

const TermColor = @import("terminal").Color;

const std = @import("std");
const log = std.log.scoped(.Gfx_Camera);
const pi = std.math.pi;
