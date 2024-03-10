const gl = @import("zopengl").bindings;

const std = @import("std");
const log = std.log.scoped(.gfxMesh);

const Buffer = @import("Buffer.zig");

pub const Mode = enum(gl.Enum) {
    triangles = gl.TRIANGLES,
    triangle_strip = gl.TRIANGLE_STRIP,
    lines = gl.LINES,
    points = gl.POINTS,
};

const Self = @This();

id: gl.Uint,
name: []const u8,
len: gl.Sizei,
mode: Mode,
ebo: ?*Buffer,

pub const InitInfo = struct {
    name: []const u8,
    buffers: []const *Buffer,
    len: gl.Sizei = 0,
    mode: Mode = .triangles,
    ebo: ?*Buffer = null,
};

pub fn init(info: InitInfo) Self {
    var id: gl.Uint = 0;
    gl.genVertexArrays(1, &id);
    for (info.buffers, 0..) |buffer, i| {
        gl.bindVertexArray(id);
        gl.bindBuffer(gl.ARRAY_BUFFER, buffer.id);
        gl.enableVertexAttribArray(@intCast(i));
        gl.vertexAttribPointer(@intCast(i), buffer.vertsize, @intFromEnum(buffer.datatype), gl.FALSE, 0, null);
    }
    return .{
        .id = id,
        .name = info.name,
        .len = info.len,
        .mode = info.mode,
        .ebo = info.ebo,
    };
}

pub fn deinit(self: Self) void {
    gl.deleteVertexArrays(1, &self.id);
}

pub fn draw(self: Self) void {
    gl.bindVertexArray(self.id);
    if (self.ebo) |ebo| {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo.id);
        gl.drawElements(@intFromEnum(self.mode), self.len, @intFromEnum(ebo.datatype), null);
    } else {
        gl.drawArrays(@intFromEnum(self.mode), 0, self.len);
    }
}
