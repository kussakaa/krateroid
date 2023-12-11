const std = @import("std");
const log = std.log.scoped(.drawer);
const c = @import("../c.zig");

const Vao = @import("Vao.zig");

const Self = @This();
id: u32,
len: u32,

pub fn init(
    data: []const u32,
    usage: enum(u32) { static = c.GL_STATIC_DRAW, dynamic = c.GL_DYNAMIC_DRAW },
) !Self {
    var id: u32 = undefined;
    c.glGenBuffers(1, &id);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, id);
    c.glBufferData(
        c.GL_ELEMENT_ARRAY_BUFFER,
        @intCast(data.len * @sizeOf(u32)),
        @as(*const anyopaque, &data[0]),
        @intFromEnum(usage),
    );

    const self = Self{
        .id = id,
        .len = @as(u32, @intCast(data.len)),
    };
    log.debug("init {}", .{self});
    return self;
}

pub fn deinit(self: Self) void {
    log.debug("deinit {}", .{self});
    c.glDeleteBuffers(1, &self.id);
}

pub fn draw(
    self: Self,
    vao: Vao,
    mode: enum(u32) {
        triangles = c.GL_TRIANGLES,
        triangle_strip = c.GL_TRIANGLE_STRIP,
        lines = c.GL_LINES,
    },
) void {
    c.glBindVertexArray(vao.id);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.id);
    c.glDrawElements(@intCast(@intFromEnum(mode)), @intCast(self.len), c.GL_UNSIGNED_INT, null);
}

//pub fn subdata(self: Verts, data: []const f32) !void {
//    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
//    c.glBufferSubData(
//        c.GL_ARRAY_BUFFER,
//        0,
//        @as(c_long, @intCast(data.len * @sizeOf(f32))),
//        @as(*const anyopaque, &data[0]),
//    );
//    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
//    try glGetError();
//}
