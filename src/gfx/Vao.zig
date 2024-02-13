const std = @import("std");
const gl = @import("zopengl").bindings;

const log = std.log.scoped(.gfx);

const wrapper = @import("wrapper.zig");
const Mode = wrapper.Mode;
const Vbo = @import("Vbo.zig");
const Self = @This();

id: u32,
len: u32,

pub fn init(attribs: []const struct { size: u32, vbo: Vbo }) !Self {
    var id: u32 = undefined;

    gl.genVertexArrays(1, &id);
    gl.bindVertexArray(id);

    for (attribs, 0..) |attrib, i| {
        gl.bindBuffer(gl.ARRAY_BUFFER, attrib.vbo.id);
        gl.enableVertexAttribArray(@intCast(i));
        gl.vertexAttribPointer(@intCast(i), @intCast(attrib.size), @intFromEnum(attrib.vbo.type), gl.FALSE, 0, null);
    }

    const self = Self{
        .id = id,
        .len = attribs[0].vbo.len / attribs[0].size,
    };

    log.debug("init {}", .{self});
    return self;
}

pub fn deinit(self: Self) void {
    log.debug("deinit {}", .{self});
    gl.deleteVertexArrays(1, &self.id);
}

pub fn draw(self: Self, mode: Mode) void {
    gl.bindVertexArray(self.id);
    gl.drawArrays(@intFromEnum(mode), 0, @intCast(self.len));
}
