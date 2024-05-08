const gfx = @import("../../gfx.zig");
const lines = @import("../../shape.zig").lines;

var vbo: gfx.Buffer = undefined;
var cbo: gfx.Buffer = undefined;
var mesh: gfx.Mesh = undefined;

pub fn init() !void {
    vbo = try gfx.Buffer.init(.{
        .name = "shape.lines.vbo",
        .target = .vbo,
        .datatype = .f32,
        .vertsize = 4,
        .usage = .dynamic_draw,
    });
    vbo.data(lines.vertexBytes());

    cbo = try gfx.Buffer.init(.{
        .name = "shape.lines.cbo",
        .target = .vbo,
        .datatype = .f32,
        .vertsize = 4,
        .usage = .dynamic_draw,
    });
    cbo.data(lines.colorBytes());

    mesh = try gfx.Mesh.init(.{
        .name = "shape.lines.mesh",
        .buffers = &.{ vbo, cbo },
        .vertcnt = lines.max * 2,
        .drawmode = .lines,
    });
}

pub fn deinit() void {
    defer vbo.deinit();
    defer cbo.deinit();
    defer mesh.deinit();
}

pub fn draw() void {
    vbo.subdata(0, lines.vertexBytes());
    cbo.subdata(0, lines.colorBytes());
    mesh.draw();
}
