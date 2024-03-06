const std = @import("std");
const gl = @import("zopengl").bindings;

const log = std.log.scoped(.gfx);
const Allocator = std.mem.Allocator;

const Type = enum(u32) {
    vert = gl.VERTEX_SHADER,
    frag = gl.FRAGMENT_SHADER,
};

const Self = @This();
id: u32,

pub fn init(
    allocator: Allocator,
    source: []const u8,
    @"type": Type,
) !Self {
    const id = gl.createShader(@intFromEnum(@"type"));
    gl.shaderSource(id, 1, &source.ptr, @ptrCast(&.{@as(gl.Int, @intCast(source.len))}));
    gl.compileShader(id);

    // error catching
    var succes: i32 = 1;
    gl.getShaderiv(id, gl.COMPILE_STATUS, &succes);
    if (succes == 0) {
        var info_log_len: i32 = 0;
        gl.getShaderiv(id, gl.INFO_LOG_LENGTH, &info_log_len);
        const info_log = try allocator.alloc(u8, @intCast(info_log_len));
        defer allocator.free(info_log);
        gl.getShaderInfoLog(id, info_log_len, null, info_log.ptr);
        log.err("shader {} compilation failed: {s}\n", .{ id, info_log });
        return error.ShaderCompilation;
    }

    const self = Self{ .id = id };
    return self;
}

pub fn deinit(self: Self) void {
    gl.deleteShader(self.id);
}
