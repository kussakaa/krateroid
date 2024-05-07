const std = @import("std");
const zm = @import("zmath");
const log = std.log.scoped(.drawerGui);
const gfx = @import("../gfx.zig");
const shape = @import("../shape.zig");
const camera = @import("../camera.zig");

const lines = @import("shape/lines.zig");

var program: gfx.Program = undefined;
const uniform = struct {
    var model: gfx.Uniform = undefined;
    var view: gfx.Uniform = undefined;
    var proj: gfx.Uniform = undefined;
};

pub fn init() !void {
    program = try gfx.Program.init("shape");
    uniform.model = try gfx.Uniform.init(program, "model");
    uniform.view = try gfx.Uniform.init(program, "view");
    uniform.proj = try gfx.Uniform.init(program, "proj");

    try lines.init();
}

pub fn deinit() void {
    program.deinit();
    lines.deinit();
}

pub fn draw() void {
    program.use();
    uniform.model.set(zm.identity());
    uniform.view.set(camera.view);
    uniform.proj.set(camera.proj);

    lines.draw();
}
