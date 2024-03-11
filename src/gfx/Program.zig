const std = @import("std");
const gl = @import("zopengl").bindings;

const log = std.log.scoped(.gfx);
const Allocator = std.mem.Allocator;
const Array = std.ArrayList;
const Shader = @import("Shader.zig");

pub const Id = usize;
const Self = @This();

id: Self.Id,
name: []const u8,
