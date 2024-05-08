const chunk = @import("chunk.zig");

pub const width = 4;
pub const height = 2;
pub const volume = width * width * height;

var init: [volume]bool = [1]bool{false} ** volume;
var update: [volume]u32 = [1]u32{0} ** volume;
var blocks: [volume]*chunk.Blocks = undefined;
