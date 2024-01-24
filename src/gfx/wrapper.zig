const gl = @import("zopengl");

pub const Type = enum(gl.Enum) {
    i8 = gl.BYTE,
    u8 = gl.UNSIGNED_BYTE,
    i16 = gl.SHORT,
    u16 = gl.UNSIGNED_SHORT,
    i32 = gl.INT,
    u32 = gl.UNSIGNED_INT,
    f32 = gl.FLOAT,

    pub fn from(comptime T: type) Type {
        return switch (T) {
            i8 => .i8,
            u8 => .u8,
            i16 => .i16,
            u16 => .u16,
            i32 => .i32,
            u32 => .u32,
            f32 => .f32,
            else => @compileError("gfx.Type.from() not implemented for type: " ++ @typeName(T)),
        };
    }
};

pub const Mode = enum(gl.Enum) {
    triangles = gl.TRIANGLES,
    triangle_strip = gl.TRIANGLE_STRIP,
    lines = gl.LINES,
};

pub const Usage = enum(gl.Enum) {
    static = gl.STATIC_DRAW,
    dynamic = gl.DYNAMIC_DRAW,
};

pub const PolygonMode = enum(gl.Enum) {
    point = gl.POINT,
    line = gl.LINE,
    fill = gl.FILL,
};
