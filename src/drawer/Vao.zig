const std = @import("std");
const log = std.log.scoped(.drawer);
const c = @import("../c.zig");

const Vbo = @import("Vbo.zig");
const Self = @This();
id: u32,

pub fn init(attribs: []const struct { size: u32, vbo: Vbo }) !Self {
    var id: u32 = undefined;

    // создание объекта аттрибутов вершин
    c.glGenVertexArrays(1, &id);
    c.glBindVertexArray(id);

    for (attribs, 0..) |attrib, i| {
        c.glBindBuffer(c.GL_ARRAY_BUFFER, attrib.vbo.id);
        c.glEnableVertexAttribArray(@intCast(i));
        c.glVertexAttribPointer(@intCast(i), @intCast(attrib.size), c.GL_FLOAT, c.GL_FALSE, 0, null);
    }

    const self = Self{
        .id = id,
    };

    log.debug("init {}", .{self});
    return self;
}

pub fn deinit(self: Self) void {
    log.debug("deinit {}", .{self});
    c.glDeleteVertexArrays(1, &self.id);
}

//pub fn draw(self: Self, mode: enum(u32) {
//    triangle_strip = c.GL_TRIANGLE_STRIP,
//    triangles = c.GL_TRIANGLES,
//    lines = c.GL_LINES,
//}) void {
//    c.glBindVertexArray(self.id);
//    c.glDrawArrays(@intCast(@intFromEnum(mode)), 0, @intCast(self.len));
//    c.glBindVertexArray(0);
//}
