const std = @import("std");
const Allocator = std.mem.Allocator;

const Self = @This();

data: [16]?[]u8,

pub fn init() !Self {}
