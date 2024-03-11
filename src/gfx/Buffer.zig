const gl = @import("zopengl").bindings;

pub const Id = usize;

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

id: Self.Id,
name: []const u8,
target: Self.Target,
datatype: Self.DataType,
vertsize: Self.VertSize,
usage: Self.Usage,
