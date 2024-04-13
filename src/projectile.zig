const std = @import("std");
const log = std.log.scoped(.projectile);
const testing = std.testing;
const zm = @import("zmath");

// STATE

const items = struct {
    const max_len = 1024;
    var pos: [max_len]zm.F32x4 = undefined;
    var dir: [max_len]zm.F32x4 = undefined;
};

// IMPLS

/// initialization all projectiles
pub fn init() void {
    @memset(items.pos[0..], zm.f32x4s(0.0));
    @memset(items.dir[0..], zm.f32x4s(0.0));
}

/// deinitialization all projectiles
pub fn deinit() void {}
pub fn update() void {}

/// get maximum peojectile count
pub inline fn getMaxCnt() comptime_int {
    return items.max_cnt;
}

/// get position for all projectiles as bytes
pub inline fn getPosBytes() []const u8 {
    return std.mem.sliceAsBytes(items.pos[0..]);
}
