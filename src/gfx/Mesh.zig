const gl = @import("zopengl").bindings;

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
len: gl.Sizei = 0,
mode: Mode = .triangles,
ebo: ?*Buffer = null,

pub fn init(name: []const u8) Self {
    var id: gl.Uint = 0;
    gl.genVertexArrays(1, &id);
    return .{ .id = id, .name = name };
}

pub fn deinit(self: Self) void {
    gl.deleteVertexArrays(1, &self.id);
}

pub fn bindBuffer(self: Self, i: gl.Uint, buffer: *const Buffer) void {
    gl.bindVertexArray(self.id);
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer.id);
    gl.enableVertexAttribArray(i);
    gl.vertexAttribPointer(i, buffer.vertsize, @intFromEnum(buffer.datatype), gl.FALSE, 0, null);
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
