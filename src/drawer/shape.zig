const std = @import("std");
const zm = @import("zmath");
const log = std.log.scoped(.drawerGui);
const gfx = @import("../gfx.zig");
const shape = @import("../shape.zig");
const camera = @import("../camera.zig");

const _data = struct {
    const line = struct {
        var vertex_buffer: gfx.Buffer = undefined;
        var color_buffer: gfx.Buffer = undefined;
        var mesh: gfx.Mesh = undefined;
    };

    var program: gfx.Program = undefined;
    const uniform = struct {
        var model: gfx.Uniform = undefined;
        var view: gfx.Uniform = undefined;
        var proj: gfx.Uniform = undefined;
    };
};

pub fn init() !void {
    _data.line.vertex_buffer = try gfx.Buffer.init(.{
        .name = "shape line vertex",
        .target = .vbo,
        .datatype = .f32,
        .vertsize = 4,
        .usage = .dynamic_draw,
    });
    _data.line.vertex_buffer.data(shape.lines.vertexBytes());

    _data.line.color_buffer = try gfx.Buffer.init(.{
        .name = "shape line color",
        .target = .vbo,
        .datatype = .f32,
        .vertsize = 4,
        .usage = .dynamic_draw,
    });
    _data.line.color_buffer.data(shape.lines.colorBytes());

    _data.line.mesh = try gfx.Mesh.init(.{
        .name = "shape line mesh",
        .buffers = &.{ _data.line.vertex_buffer, _data.line.color_buffer },
        .vertcnt = shape.lines.max_cnt * 2,
        .drawmode = .lines,
    });

    _data.program = try gfx.Program.init("shape");
    _data.uniform.model = try gfx.Uniform.init(_data.program, "model");
    _data.uniform.view = try gfx.Uniform.init(_data.program, "view");
    _data.uniform.proj = try gfx.Uniform.init(_data.program, "proj");
}

pub fn deinit() void {
    _data.program.deinit();
    _data.line.mesh.deinit();
    _data.line.vertex_buffer.deinit();
    _data.line.color_buffer.deinit();
}

pub fn draw() void {
    _data.program.use();
    _data.uniform.model.set(zm.identity());
    _data.uniform.view.set(camera.view);
    _data.uniform.proj.set(camera.proj);

    _data.line.vertex_buffer.subdata(0, shape.lines.vertexBytes());
    _data.line.color_buffer.subdata(0, shape.lines.colorBytes());
    _data.line.mesh.draw();
}
