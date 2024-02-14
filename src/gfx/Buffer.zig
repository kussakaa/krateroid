const gl = @import("zopengl").bindings;

const Id = gl.Uint;

pub const Target = enum(gl.Enum) {
    array = gl.ARRAY_BUFFER,
    elements_array = gl.ELEMENT_ARRAY_BUFFER,
};

pub const Usage = enum(gl.Enum) {
    static_draw = gl.STATIC_DRAW,
    dynamic_draw = gl.DYNAMIC_DRAW,
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

const Self = @This();

id: Id,
name: []const u8,
data_type: DataType = .f32,
vertex_size: gl.Sizei = 3,

pub fn init(name: []const u8) Self {
    var id: gl.Uint = 0;
    gl.genBuffers(1, &id);
    return .{ .id = id, .name = name };
}

pub fn deinit(self: Self) void {
    gl.deleteBuffers(1, &self.id);
}

pub fn data(self: Self, target: Target, bytes: []const u8, usage: Usage) void {
    gl.bindBuffer(@intFromEnum(target), self.id);
    gl.bufferData(
        @intFromEnum(target),
        @intCast(bytes.len),
        bytes.ptr,
        @intFromEnum(usage),
    );
}

pub fn subdata(self: Self, target: Target, offset: usize, bytes: []const u8) void {
    gl.bindBuffer(@intFromEnum(target), self.id);
    gl.bufferSubData(
        @intFromEnum(target),
        @intCast(offset),
        @intCast(bytes.len),
        bytes.ptr,
    );
}
