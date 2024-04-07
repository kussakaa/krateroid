const std = @import("std");
const log = std.log.scoped(.shape);
const zm = @import("zmath");

const LineId = usize;

const _lines = struct {
    const max_cnt = 1024;
    var vertex: [max_cnt * 2]zm.F32x4 = undefined;
    var color: [max_cnt * 2]zm.F32x4 = undefined;
};

pub fn init() void {
    initLines();
}

pub fn deinit() void {
    deinitLines();
}

fn initLines() void {
    @memset(_lines.vertex[0..], zm.f32x4s(0.0));
    @memset(_lines.color[0..], zm.f32x4s(0.0));
}

fn deinitLines() void {}

pub fn initLine(id: LineId, info: struct {
    v1: zm.F32x4,
    v2: zm.F32x4,
    c1: zm.F32x4 = zm.f32x4s(1.0),
    c2: zm.F32x4 = zm.f32x4s(1.0),
}) void {
    _lines.vertex[id * 2 + 0] = info.v1;
    _lines.vertex[id * 2 + 1] = info.v2;
    _lines.color[id * 2 + 0] = info.c1;
    _lines.color[id * 2 + 1] = info.c2;
}

pub inline fn showLine(id: LineId, show: bool) void {
    _lines.color[id * 2 + 0][3] = @floatFromInt(@intFromBool(show));
    _lines.color[id * 2 + 1][3] = @floatFromInt(@intFromBool(show));
}

pub inline fn linesMaxCnt() comptime_int {
    return _lines.max_cnt;
}

pub inline fn linesVertexBytes() []const u8 {
    return std.mem.sliceAsBytes(_lines.vertex[0..]);
}

pub inline fn linesColorBytes() []const u8 {
    return std.mem.sliceAsBytes(_lines.color[0..]);
}
