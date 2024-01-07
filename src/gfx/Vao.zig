const std = @import("std");
const log = std.log.scoped(.gfx);
const c = @import("../c.zig");

const Mode = @import("util.zig").Mode;
const Vbo = @import("Vbo.zig");
const Self = @This();

id: u32,
len: u32,

pub fn init(attribs: []const struct { size: u32, vbo: Vbo }) !Self {
    var id: u32 = undefined;

    // создание объекта аттрибутов вершин
    c.glGenVertexArrays(1, &id);
    c.glBindVertexArray(id);

    for (attribs, 0..) |attrib, i| {
        c.glBindBuffer(c.GL_ARRAY_BUFFER, attrib.vbo.id);
        c.glEnableVertexAttribArray(@intCast(i));
        c.glVertexAttribPointer(@intCast(i), @intCast(attrib.size), @intFromEnum(attrib.vbo.type), c.GL_FALSE, 0, null);
    }

    const self = Self{
        .id = id,
        .len = @as(u32, @intCast(attribs[0].vbo.len)) / attribs[0].size,
    };

    log.debug("init {}", .{self});
    return self;
}

pub fn deinit(self: Self) void {
    log.debug("deinit {}", .{self});
    c.glDeleteVertexArrays(1, &self.id);
}

pub fn draw(self: Self, mode: Mode) void {
    c.glBindVertexArray(self.id);
    c.glDrawArrays(@intCast(@intFromEnum(mode)), 0, @intCast(self.len));
    c.glBindVertexArray(0);
}
