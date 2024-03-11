const gl = @import("zopengl").bindings;
pub const Type = enum(u32) {
    vert = gl.VERTEX_SHADER,
    frag = gl.FRAGMENT_SHADER,
};
