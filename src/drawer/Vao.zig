const std = @import("std");
const log = std.log.scoped(.drawer);
const c = @import("../c.zig");

const Vbo = @import("Vbo.zig");

const Mode = enum(u32) {
    triangle_strip = c.GL_TRIANGLE_STRIP,
    triangles = c.GL_TRIANGLES,
    lines = c.GL_LINES,
};

const Self = @This();
id: u32, // объект аттрибутов вершин

pub fn init(info: struct {
    attributes: []const u32,
    vbo: []const Vbo,
}) !Self {
    if (info.attributes.len != info.vbo.len) return error.INVALID_ATTRIBUTES_COUNT;
    var id: u32 = undefined;

    // создание объекта аттрибутов вершин
    c.glGenVertexArrays(1, &id);
    c.glBindVertexArray(id);

    for (info.attributes, 0..) |size, i| {
        c.glEnableVertexAttribArray(@intCast(i));
        c.glBindBuffer(c.GL_ARRAY_BUFFER, info.vbo[i].id);
        c.glVertexAttribPointer(@intCast(i), @intCast(size), c.GL_FLOAT, c.GL_FALSE, 0, null);
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

//pub fn draw(self: Self) void {
//    c.glBindVertexArray(self.id);
//    c.glDrawArrays(@intCast(@intFromEnum(self.mode)), 0, @intCast(self.len));
//    c.glBindVertexArray(0);
//}
