const zm = @import("zmath");

pub const Id = usize;
pub const len = 256;
pub var cnt: usize = 0;
pub const vertex_size = 3 * 2;
pub var vertex = [1]f32{0.0} ** (vertex_size * len);
pub const color_size = 4 * 2;
pub var color = [1]f32{0.0} ** (color_size * len);

pub inline fn add(info: struct {
    v1: zm.F32x4,
    v2: zm.F32x4,
    c1: zm.F32x4 = zm.f32x4s(1.0),
    c2: zm.F32x4 = zm.f32x4s(1.0),
}) !Id {
    const id = cnt;
    cnt += 1;

    setVertex1(id, info.v1);
    setVertex2(id, info.v2);
    setColor1(id, info.c1);
    setColor2(id, info.c2);

    return id;
}

pub inline fn setVertex1(id: Id, v: zm.F32x4) void {
    vertex[id * vertex_size + 0] = v[0];
    vertex[id * vertex_size + 1] = v[1];
    vertex[id * vertex_size + 2] = v[2];
}

pub inline fn setVertex2(id: Id, v: zm.F32x4) void {
    vertex[id * vertex_size + 3] = v[0];
    vertex[id * vertex_size + 4] = v[1];
    vertex[id * vertex_size + 5] = v[2];
}

pub inline fn setColor1(id: Id, c: zm.F32x4) void {
    color[id * color_size + 0] = c[0];
    color[id * color_size + 1] = c[1];
    color[id * color_size + 2] = c[2];
    color[id * color_size + 3] = c[3];
}

pub inline fn setColor2(id: Id, c: zm.F32x4) void {
    color[id * color_size + 4] = c[0];
    color[id * color_size + 5] = c[1];
    color[id * color_size + 6] = c[2];
    color[id * color_size + 7] = c[3];
}
