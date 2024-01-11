const c = @import("../c.zig");

pub const Type = enum(u32) {
    i8 = c.GL_BYTE,
    u8 = c.GL_UNSIGNED_BYTE,
    i16 = c.GL_SHORT,
    u16 = c.GL_UNSIGNED_SHORT,
    i32 = c.GL_INT,
    u32 = c.GL_UNSIGNED_INT,
    f32 = c.GL_FLOAT,

    pub fn from(comptime T: type) Type {
        return switch (T) {
            i8 => .i8,
            u8 => .u8,
            i16 => .i16,
            u16 => .u16,
            i32 => .i32,
            u32 => .u32,
            f32 => .f32,
            else => @compileError("invalid type for gfx.Type.from()"),
        };
    }
};

pub const Mode = enum(u32) {
    triangles = c.GL_TRIANGLES,
    triangle_strip = c.GL_TRIANGLE_STRIP,
    lines = c.GL_LINES,
};

pub const Usage = enum(u32) {
    static = c.GL_STATIC_DRAW,
    dynamic = c.GL_DYNAMIC_DRAW,
};

pub const PolygonMode = enum(u32) {
    point = c.GL_POINT,
    line = c.GL_LINE,
    fill = c.GL_FILL,
};
