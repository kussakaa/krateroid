const gl = @import("zopengl").bindings;

const Buffer = @import("Buffer.zig");

pub const Mode = enum(gl.Enum) {
    triangles = gl.TRIANGLES,
    triangle_strip = gl.TRIANGLE_STRIP,
    lines = gl.LINES,
};

const Self = @This();

id: gl.Uint,
name: []const u8,
count: gl.Sizei = 0,
mode: Mode = .triangles,
ebo: Buffer = .{ .id = 0, .name = "default" },

pub fn init(name: []const u8) Self {
    var id: gl.Uint = 0;
    gl.genVertexArrays(1, &id);
    return .{ .id = id, .name = name };
}

pub fn deinit(self: Self) void {
    gl.deleteVertexArrays(1, &self.id);
}

pub fn bindBuffer(self: Self, i: gl.Uint, buffer: Buffer) void {
    gl.bindVertexArray(self.id);
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer.id);
    gl.enableVertexAttribArray(i);
    gl.vertexAttribPointer(i, buffer.vertex_size, @intFromEnum(buffer.data_type), gl.FALSE, 0, null);
}

pub fn draw(self: Self) void {
    gl.bindVertexArray(self.id);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ebo.id);
    gl.drawArrays(@intFromEnum(self.mode), 0, self.count);
}
