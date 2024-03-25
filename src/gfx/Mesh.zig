const std = @import("std");
const log = std.log.scoped(.gfx);

const gl = @import("zopengl").bindings;
const Buffer = @import("Buffer.zig");

pub const Id = gl.Uint;
pub const VertCnt = gl.Sizei;

pub const DrawMode = enum(gl.Enum) {
    triangles = gl.TRIANGLES,
    triangle_strip = gl.TRIANGLE_STRIP,
    lines = gl.LINES,
    points = gl.POINTS,
};

const Self = @This();

id: Id,
name: []const u8,
vertcnt: VertCnt,
drawmode: DrawMode,
ebo: ?*Buffer,

pub fn init(info: struct {
    name: []const u8,
    buffers: []const Buffer,
    vertcnt: VertCnt,
    drawmode: DrawMode,
    ebo: ?*Buffer = null,
}) !Self {
    var id: Id = undefined;
    gl.genVertexArrays(1, &id);
    gl.bindVertexArray(id);
    for (info.buffers, 0..) |buffer, i| {
        gl.bindBuffer(@intFromEnum(buffer.target), buffer.id);
        gl.enableVertexAttribArray(@intCast(i));
        gl.vertexAttribPointer(@intCast(i), buffer.vertsize, @intFromEnum(buffer.datatype), gl.FALSE, 0, null);
    }
    log.debug("init mesh {s} {}", .{ info.name, id });
    return .{
        .id = id,
        .name = info.name,
        .vertcnt = info.vertcnt,
        .drawmode = info.drawmode,
        .ebo = info.ebo,
    };
}

pub fn deinit(self: Self) void {
    gl.deleteVertexArrays(1, &self.id);
}

pub fn draw(self: Self) void {
    gl.bindVertexArray(self.id);
    if (self.ebo) |ebo| {
        gl.bindBuffer(@intFromEnum(ebo.target), ebo.id);
        gl.drawElements(@intFromEnum(self.drawmode), self.vertcnt, @intFromEnum(ebo.datatype), null);
    } else {
        gl.drawArrays(@intFromEnum(self.drawmode), 0, self.vertcnt);
    }
}
