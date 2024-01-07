const std = @import("std");
const log = std.log.scoped(.gfxVbo);
const c = @import("../c.zig");

const Type = @import("util.zig").Type;
const Usage = @import("util.zig").Usage;

const Self = @This();
id: u32,
len: u32,
type: Type,

pub fn init(
    comptime T: type,
    data: []const T,
    usage: Usage,
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
        .type = Type.from(T),
    };
    log.debug("init {}", .{self});
    return self;
}

pub fn deinit(self: Self) void {
    log.debug("deinit {}", .{self});
    c.glDeleteBuffers(1, &self.id);
}

pub fn subdata(self: Self, comptime T: type, data: []const T) !void {
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.id);
    c.glBufferSubData(
        c.GL_ARRAY_BUFFER,
        0,
        @intCast(data.len * @sizeOf(T)),
        @as(*const anyopaque, &data[0]),
    );
}
