const std = @import("std");
const log = std.log.scoped(.explosiion);
const testing = std.testing;
const zm = @import("zmath");

// STATE

pub const items = struct {
    /// maximum count explosiions
    pub const len = 1024;
    var init: [len]bool = [1]bool{false} ** len;
    var pos: [len]zm.F32x4 = undefined;
};

/// initialize all explosiions
pub fn init() void {}

/// deinitialize all explosiions
pub fn deinit() void {}

/// update all explosiions
pub fn update() void {}

/// get position for all explosiions as bytes
pub inline fn getPosBytes() []const u8 {
    return std.mem.sliceAsBytes(items.pos[0..]);
}
