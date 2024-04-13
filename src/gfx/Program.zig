const std = @import("std");
const log = std.log.scoped(.gfx);
const gl = @import("zopengl").bindings;

const Allocator = std.mem.Allocator;
const Shader = @import("Shader.zig");

pub const Id = gl.Uint;

const Self = @This();

id: Id,
name: []const u8,

pub fn init(comptime name: []const u8) !Self {
    const id = gl.createProgram();

    const vert = try Shader.init(name, .vert);
    defer vert.deinit();
    gl.attachShader(id, vert.id);
    defer gl.detachShader(id, vert.id);

    const frag = try Shader.init(name, .frag);
    defer frag.deinit();
    gl.attachShader(id, frag.id);
    defer gl.detachShader(id, frag.id);

    gl.linkProgram(id);

    const s = struct {
        var buffer = [1]u8{0} ** 4096;
    };

    // error catching
    var succes: gl.Int = 1;
    gl.getProgramiv(id, gl.LINK_STATUS, &succes);
    if (succes <= 0) {
        var info_log_len: gl.Int = 0;
        gl.getProgramiv(id, gl.INFO_LOG_LENGTH, &info_log_len);
        const len: usize = @intCast(info_log_len);
        gl.getProgramInfoLog(id, info_log_len, null, s.buffer[0..len].ptr);
        log.err("program {s} failed linkage: {s}", .{ name, s.buffer[0..len] });
        return error.ShaderProgramLinkage;
    }

    log.debug("init program {s}", .{name});
    return .{ .id = id, .name = name };
}

pub fn deinit(self: Self) void {
    gl.deleteProgram(self.id);
}

pub fn use(self: Self) void {
    gl.useProgram(self.id);
}
