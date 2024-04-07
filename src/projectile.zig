const std = @import("std");
const log = std.log.scoped(.projectile);
const testing = std.testing;
const zm = @import("zmath");

// CONSTS

/// Max projectiles count
const max_cnt = 1024;

// STATE

const _projectiles = struct {
    var pos: [max_cnt]zm.F32x4 = undefined;
    var dir: [max_cnt]zm.F32x4 = undefined;
};

// IMPLS

/// initialization all projectiles
pub fn init() void {
    @memset(_projectiles.pos[0..], zm.f32x4s(0.0));
    @memset(_projectiles.dir[0..], zm.f32x4s(0.0));
}

/// deinitialization all projectiles
pub fn deinit() void {}
pub fn update() void {}

/// get maximum peojectile count
pub inline fn getMaxCnt() comptime_int {
    return _projectiles.max_cnt;
}

/// get position for all projectiles as bytes
pub inline fn getPosBytes() []const u8 {
    return std.mem.sliceAsBytes(_projectiles.pos[0..]);
}
