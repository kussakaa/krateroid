const gl = @import("zopengl").bindings;

pub const Id = usize;
pub const Size = @Vector(2, u32);
pub const Format = enum(gl.Enum) {
    red = gl.RED,
    rgb = gl.RGB,
    rgba = gl.RGBA,
};
const Self = @This();

id: Self.Id = 0,
name: []const u8,
size: Self.Size,
format: Self.Format,
