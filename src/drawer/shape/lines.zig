const gfx = @import("../../gfx.zig");
const lines = @import("../../shape.zig").lines;

var vertex_buffer: gfx.Buffer = undefined;
var color_buffer: gfx.Buffer = undefined;
var mesh: gfx.Mesh = undefined;

pub fn init() !void {
    vertex_buffer = try gfx.Buffer.init(.{
        .name = "shape line vertex",
        .target = .vbo,
        .datatype = .f32,
        .vertsize = 4,
        .usage = .dynamic_draw,
    });
    vertex_buffer.data(lines.vertexBytes());

    color_buffer = try gfx.Buffer.init(.{
        .name = "shape line color",
        .target = .vbo,
        .datatype = .f32,
        .vertsize = 4,
        .usage = .dynamic_draw,
    });
    color_buffer.data(lines.colorBytes());

    mesh = try gfx.Mesh.init(.{
        .name = "shape line mesh",
        .buffers = &.{ vertex_buffer, color_buffer },
        .vertcnt = lines.max_cnt * 2,
        .drawmode = .lines,
    });
}

pub fn deinit() void {
    mesh.deinit();
    vertex_buffer.deinit();
    color_buffer.deinit();
}

pub fn draw() void {
    vertex_buffer.subdata(0, lines.vertexBytes());
    color_buffer.subdata(0, lines.colorBytes());
    mesh.draw();
}
