const gl = @import("zopengl").bindings;
const Buffer = @import("Buffer.zig");

pub const Id = usize;
pub const VertCnt = gl.Sizei;

pub const DrawMode = enum(gl.Enum) {
    triangles = gl.TRIANGLES,
    triangle_strip = gl.TRIANGLE_STRIP,
    lines = gl.LINES,
    points = gl.POINTS,
};

const Self = @This();

id: Self.Id,
name: []const u8,
vertcnt: Self.VertCnt,
drawmode: Self.DrawMode,
ebo: ?Buffer.Id,
