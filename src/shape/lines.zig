const std = @import("std");
const zm = @import("zmath");

const Id = @import("line.zig").Id;

pub const max = 1024;
var vbo_data: [max * 2]zm.F32x4 = undefined;
var cbo_data: [max * 2]zm.F32x4 = undefined;

pub fn init() void {
    @memset(vbo_data[0..], zm.f32x4s(0.0));
    @memset(cbo_data[0..], zm.f32x4s(0.0));
}

pub fn add(id: Id, info: struct {
    v1: zm.F32x4,
    v2: zm.F32x4,
    c1: zm.F32x4 = zm.f32x4s(1.0),
    c2: zm.F32x4 = zm.f32x4s(1.0),
}) void {
    vbo_data[id * 2 + 0] = info.v1;
    vbo_data[id * 2 + 1] = info.v2;
    cbo_data[id * 2 + 0] = info.c1;
    cbo_data[id * 2 + 1] = info.c2;
}

pub inline fn show(id: Id, flag: bool) void {
    cbo_data[id * 2 + 0][3] = @floatFromInt(@intFromBool(flag));
    cbo_data[id * 2 + 1][3] = @floatFromInt(@intFromBool(flag));
}

pub inline fn vertexBytes() []const u8 {
    return std.mem.sliceAsBytes(vbo_data[0..]);
}

pub inline fn colorBytes() []const u8 {
    return std.mem.sliceAsBytes(cbo_data[0..]);
}
