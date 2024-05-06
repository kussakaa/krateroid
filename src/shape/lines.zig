const std = @import("std");
const zm = @import("zmath");

const Id = usize;

pub const max_cnt = 1024;
var vertex: [max_cnt * 2]zm.F32x4 = undefined;
var color: [max_cnt * 2]zm.F32x4 = undefined;

pub fn init() void {
    @memset(vertex[0..], zm.f32x4s(0.0));
    @memset(color[0..], zm.f32x4s(0.0));
}

pub fn add(id: Id, info: struct {
    v1: zm.F32x4,
    v2: zm.F32x4,
    c1: zm.F32x4 = zm.f32x4s(1.0),
    c2: zm.F32x4 = zm.f32x4s(1.0),
}) void {
    vertex[id * 2 + 0] = info.v1;
    vertex[id * 2 + 1] = info.v2;
    color[id * 2 + 0] = info.c1;
    color[id * 2 + 1] = info.c2;
}

pub inline fn show(id: Id, flag: bool) void {
    color[id * 2 + 0][3] = @floatFromInt(@intFromBool(flag));
    color[id * 2 + 1][3] = @floatFromInt(@intFromBool(flag));
}

pub inline fn vertexBytes() []const u8 {
    return std.mem.sliceAsBytes(vertex[0..]);
}

pub inline fn colorBytes() []const u8 {
    return std.mem.sliceAsBytes(color[0..]);
}
