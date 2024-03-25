const std = @import("std");
const stb = @import("zstbi");
const gl = @import("zopengl").bindings;
const log = std.log.scoped(.gfx);

const Allocator = std.mem.Allocator;

pub const Buffer = @import("gfx/Buffer.zig");
pub const Mesh = @import("gfx/Mesh.zig");
pub const Texture = @import("gfx/Texture.zig");
pub const Shader = @import("gfx/Shader.zig");
pub const Program = @import("gfx/Program.zig");
pub const Uniform = @import("gfx/Uniform.zig");

pub fn init(info: struct { allocator: Allocator }) !void {
    stb.init(info.allocator);
}

pub fn deinit() void {
    stb.deinit();
}
