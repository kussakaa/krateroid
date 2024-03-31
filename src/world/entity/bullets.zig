const std = @import("std");
const zm = @import("zmath");

pub const Id = usize;

pub const len = 1024;
pub var cnt: usize = 0;

pub var pos: [len]zm.F32x4 = undefined;
pub var dir: [len]zm.F32x4 = undefined;

pub fn init() void {}
pub fn deinit() void {}

pub fn update() void {
    for (0..len) |i| pos[i] += dir[i];
}

pub inline fn add(info: struct {
    pos: zm.F32x4 = .{ 0.0, 0.0, 0.0, 1.0 },
    dir: zm.F32x4 = .{ 0.0, 0.0, 0.0, 1.0 },
}) Id {
    const id = cnt;
    setPos(id, info.pos);
    setDir(id, info.dir);
    cnt += 1;
    return id;
}

pub inline fn getPosBytes() []const u8 {
    return std.mem.sliceAsBytes(pos[0..]);
}

pub inline fn setPos(id: Id, v: zm.F32x4) void {
    pos[id] = v;
}

pub inline fn setDir(id: Id, v: zm.F32x4) void {
    dir[id] = v;
}

pub inline fn move(id: Id, v: zm.F32x4) void {
    pos[id] += v;
}
