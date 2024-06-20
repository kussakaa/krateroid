const std = @import("std");
const log = std.log.scoped(.drawer);
const zm = @import("zmath");
const gl = @import("zopengl").bindings;

const shape = @import("drawer/shape.zig");
const gui = @import("drawer/gui.zig");

const config = @import("config.zig");

const Allocator = std.mem.Allocator;

pub fn init(allocator: Allocator) !void {
    gl.enable(gl.MULTISAMPLE);
    gl.enable(gl.LINE_SMOOTH);
    gl.enable(gl.BLEND);
    gl.enable(gl.CULL_FACE);

    gl.lineWidth(2.0);
    gl.pointSize(3.0);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.cullFace(gl.FRONT);
    gl.frontFace(gl.CW);

    try shape.init();
    try gui.init(allocator);
}

pub fn deinit() void {
    shape.deinit();
    gui.deinit();
}

pub fn draw() !void {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.clearColor(config.drawer.background.color[0], config.drawer.background.color[1], config.drawer.background.color[2], config.drawer.background.color[3]);

    gl.enable(gl.DEPTH_TEST);
    gl.polygonMode(gl.FRONT_AND_BACK, if (config.debug.show_grid) gl.LINE else gl.FILL);

    gl.disable(gl.DEPTH_TEST);
    shape.draw();

    gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);
    gui.draw();
}
