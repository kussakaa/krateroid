const std = @import("std");
const log = std.log.scoped(.gfx);
const gl = @import("zopengl").bindings;

pub const Id = gl.Uint;

pub const Target = enum(gl.Enum) {
    vbo = gl.ARRAY_BUFFER,
    ebo = gl.ELEMENT_ARRAY_BUFFER,
};

pub const DataType = enum(gl.Enum) {
    i8 = gl.BYTE,
    u8 = gl.UNSIGNED_BYTE,
    i16 = gl.SHORT,
    u16 = gl.UNSIGNED_SHORT,
    i32 = gl.INT,
    u32 = gl.UNSIGNED_INT,
    f32 = gl.FLOAT,
};

pub const VertSize = gl.Int;

pub const Usage = enum(gl.Enum) {
    static_draw = gl.STATIC_DRAW,
    dynamic_draw = gl.DYNAMIC_DRAW,
};

const Self = @This();

id: Id,
name: []const u8,
target: Target,
datatype: DataType,
vertsize: VertSize,
usage: Usage,

pub fn init(info: struct {
    name: []const u8,
    target: Target,
    datatype: DataType = .f32,
    vertsize: VertSize = 3,
    usage: Usage = .static_draw,
}) !Self {
    var id: gl.Uint = 0;
    gl.genBuffers(1, &id);
    log.debug("init buffer {s} {}", .{ info.name, id });
    return .{
        .id = id,
        .name = info.name,
        .target = info.target,
        .datatype = info.datatype,
        .vertsize = info.vertsize,
        .usage = info.usage,
    };
}

pub fn deinit(self: Self) void {
    gl.deleteBuffers(1, &self.id);
}

pub fn data(self: Self, bytes: []const u8) void {
    gl.bindBuffer(@intFromEnum(self.target), self.id);
    gl.bufferData(
        @intFromEnum(self.target),
        @intCast(bytes.len),
        bytes.ptr,
        @intFromEnum(self.usage),
    );
}

pub fn subdata(self: Self, offset: usize, bytes: []const u8) void {
    gl.bindBuffer(@intFromEnum(self.target), self.id);
    gl.bufferSubData(
        @intFromEnum(self.target),
        @intCast(offset),
        @intCast(bytes.len),
        bytes.ptr,
    );
}
