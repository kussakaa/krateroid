const std = @import("std");

const zm = @import("zmath");
const Vec = zm.Vec;
const Mat = zm.Mat;
const Color = zm.Vec;

pub const lines = struct {
    pub const Id = usize;
    pub const len = 256;
    pub var cnt: usize = 0;
    pub const vert_size = 3 * 2;
    pub var vert = [1]f32{0.0} ** (vert_size * len);
    pub const color_size = 4 * 2;
    pub var color = [1]f32{0.0} ** (color_size * len);

    pub inline fn add(info: struct {
        p1: Vec,
        p2: Vec,
        c1: Color = .{ 1.0, 1.0, 1.0, 1.0 },
        c2: Color = .{ 1.0, 1.0, 1.0, 1.0 },
    }) !Id {
        const id = cnt;
        cnt += 1;

        setP1(id, info.p1);
        setP2(id, info.p2);
        setC1(id, info.c1);
        setC2(id, info.c2);

        return id;
    }

    pub inline fn setP1(id: Id, p: Vec) void {
        lines.vert[id * vert_size + 0] = p[0];
        lines.vert[id * vert_size + 1] = p[1];
        lines.vert[id * vert_size + 2] = p[2];
    }

    pub inline fn setP2(id: Id, p: Vec) void {
        lines.vert[id * vert_size + 3] = p[0];
        lines.vert[id * vert_size + 4] = p[1];
        lines.vert[id * vert_size + 5] = p[2];
    }

    pub inline fn setC1(id: Id, c: Color) void {
        lines.color[id * color_size + 0] = c[0];
        lines.color[id * color_size + 1] = c[1];
        lines.color[id * color_size + 2] = c[2];
        lines.color[id * color_size + 3] = c[3];
    }

    pub inline fn setC2(id: Id, c: Color) void {
        lines.color[id * color_size + 4] = c[0];
        lines.color[id * color_size + 5] = c[1];
        lines.color[id * color_size + 6] = c[2];
        lines.color[id * color_size + 7] = c[3];
    }
};
