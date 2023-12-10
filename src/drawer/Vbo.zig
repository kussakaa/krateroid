const std = @import("std");
const log = std.log.scoped(.drawer);
const c = @import("../c.zig");

const Self = @This();
id: u32,
len: u32,

pub fn init(
    comptime T: type,
    data: []const T,
    usage: enum(u32) { static = c.GL_STATIC_DRAW, dynamic = c.GL_DYNAMIC_DRAW },
) !Self {
    var id: u32 = undefined;
    c.glGenBuffers(1, &id);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, id);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @intCast(data.len * @sizeOf(T)),
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
