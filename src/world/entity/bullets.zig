const std = @import("std");
const zm = @import("zmath");
const terra = @import("../terra.zig");

pub const Id = usize;

pub const len = 1024;

var _pos: [len]zm.F32x4 = undefined;
var _dir: [len]zm.F32x4 = undefined;

pub fn init() void {}
pub fn deinit() void {}

pub fn update() void {
    for (0..len) |i| {
        move(i, getDir(i));
        if (terra.getBlock(.{
            @intFromFloat(@floor(getPos(i)[0])),
            @intFromFloat(@floor(getPos(i)[1])),
            @intFromFloat(@floor(getPos(i)[2])),
        }).id > 0) {
            setPos(i, zm.f32x4s(0.0));
            setDir(i, zm.f32x4s(0.0));
        }
    }
}

pub inline fn set(id: Id, info: struct {
    pos: zm.F32x4 = .{ 0.0, 0.0, 0.0, 1.0 },
    dir: zm.F32x4 = .{ 0.0, 0.0, 0.0, 0.0 },
}) void {
    setPos(id, info.pos);
    setDir(id, info.dir);
}

pub inline fn get(id: Id) struct {
    pos: zm.F32x4,
    dir: zm.F32x4,
} {
    return .{
        .pos = getPos(id),
        .dir = getDir(id),
    };
}

pub inline fn getPosBytes() []const u8 {
    return std.mem.sliceAsBytes(_pos[0..]);
}

pub inline fn getDirBytes() []const u8 {
    return std.mem.sliceAsBytes(_dir[0..]);
}

pub inline fn setPos(id: Id, pos: zm.F32x4) void {
    _pos[id] = pos;
}

pub inline fn getPos(id: Id) zm.F32x4 {
    return _pos[id];
}

pub inline fn setDir(id: Id, dir: zm.F32x4) void {
    _dir[id] = dir;
}

pub inline fn getDir(id: Id) zm.F32x4 {
    return _dir[id];
}

pub inline fn move(id: Id, dir: zm.F32x4) void {
    _pos[id] += dir;
}
