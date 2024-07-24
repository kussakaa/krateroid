id: Id,
name: []const u8,
target: Target,
datatype: DataType,
vertsize: VertSize,
usage: Usage,

pub fn init(config: Config) !Buffer {
    var id: Id = 0;
    gl.genBuffers(1, &id);
    log.debug("Initialization completed {s} {} ", .{ config.name, id });
    return .{
        .id = id,
        .name = config.name,
        .target = config.target,
        .datatype = config.datatype,
        .vertsize = config.vertsize,
        .usage = config.usage,
    };
}

pub fn deinit(self: Buffer) void {
    gl.deleteBuffers(1, &self.id);
}

pub fn data(self: Buffer, bytes: []const u8) void {
    gl.bindBuffer(@intFromEnum(self.target), self.id);
    gl.bufferData(
        @intFromEnum(self.target),
        @intCast(bytes.len),
        bytes.ptr,
        @intFromEnum(self.usage),
    );
}

pub fn subdata(self: Buffer, offset: usize, bytes: []const u8) void {
    gl.bindBuffer(@intFromEnum(self.target), self.id);
    gl.bufferSubData(
        @intFromEnum(self.target),
        @intCast(offset),
        @intCast(bytes.len),
        bytes.ptr,
    );
}

const Buffer = @This();

pub const Id = gl.Uint;

pub const Config = struct {
    name: []const u8,
    target: Target = .vbo,
    datatype: DataType = .f32,
    vertsize: VertSize = 3,
    usage: Usage = .static_draw,
};

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

const gl = @import("zopengl").bindings;

const std = @import("std");
const log = std.log.scoped(.Gfx_Buffer);
