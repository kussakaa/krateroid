const std = @import("std");
const zm = @import("zmath");

pub const Id = usize;
pub const len = 1024;
pub var cnt: usize = 0;
pub var vertex: [len * 2]zm.F32x4 = undefined;
pub var color: [len * 2]zm.F32x4 = undefined;

const InitInfo = struct {
    v1: zm.F32x4,
    v2: zm.F32x4,
    c1: zm.F32x4 = zm.f32x4s(1.0),
    c2: zm.F32x4 = zm.f32x4s(1.0),
};

pub fn init() void {}
pub fn deinit() void {}

pub inline fn add(info: InitInfo) Id {
    const id = cnt;
    cnt += 1;
    set(id, info);
    return id;
}

pub inline fn set(id: Id, info: InitInfo) void {
    setVertex1(id, info.v1);
    setVertex2(id, info.v2);
    setColor1(id, info.c1);
    setColor2(id, info.c2);
}

pub inline fn setVertex1(id: Id, v: zm.F32x4) void {
    vertex[id * 2 + 0] = v;
}

pub inline fn setVertex2(id: Id, v: zm.F32x4) void {
    vertex[id * 2 + 1] = v;
}

pub inline fn setColor1(id: Id, c: zm.F32x4) void {
    color[id * 2 + 0] = c;
}

pub inline fn setColor2(id: Id, c: zm.F32x4) void {
    color[id * 2 + 1] = c;
}

pub inline fn getVertexBytes() []const u8 {
    return std.mem.sliceAsBytes(vertex[0..]);
}

pub inline fn getColorBytes() []const u8 {
    return std.mem.sliceAsBytes(color[0..]);
}
