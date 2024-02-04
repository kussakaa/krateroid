const std = @import("std");
const log = std.log.scoped(.gfx);
const gl = @import("zopengl").bindings;

const wrapper = @import("wrapper.zig");
const Type = wrapper.Type;
const Mode = wrapper.Mode;
const Usage = wrapper.Usage;
const Vao = @import("Vao.zig");

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
    gl.genBuffers(1, &id);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, id);
    gl.bufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        @intCast(data.len * @sizeOf(T)),
        @as(*const anyopaque, &data[0]),
        @intFromEnum(usage),
    );

    const self = Self{
        .id = id,
        .len = @intCast(data.len),
        .type = Type.from(T),
    };
    log.debug("init {}", .{self});
    return self;
}

pub fn deinit(self: Self) void {
    log.debug("deinit {}", .{self});
    gl.DeleteBuffers(1, &self);
}

pub fn draw(
    self: Self,
    vao: Vao,
    mode: Mode,
) void {
    gl.bindVertexArray(vao.id);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.id);
    gl.drawElements(@intFromEnum(mode), self.len, @intFromEnum(self.type), null);
}

pub fn subdata(self: Self, comptime T: type, data: []const T) !void {
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.id);
    gl.bufferSubData(
        gl.ELEMENT_ARRAY_BUFFER,
        0,
        data.len * @sizeOf(T),
        @as(*const anyopaque, &data[0]),
    );
}
