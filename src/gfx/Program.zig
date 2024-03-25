const std = @import("std");
const log = std.log.scoped(.gfx);
const gl = @import("zopengl").bindings;

const Allocator = std.mem.Allocator;
const Shader = @import("Shader.zig");

pub const Id = gl.Uint;

const Self = @This();

id: Id,
name: []const u8,

pub fn init(allocator: Allocator, name: []const u8) !Self {
    const id = gl.createProgram();

    const prefix = "data/shader/";

    const vert_path = try std.mem.concatWithSentinel(allocator, u8, &.{ prefix, name, "/vert.glsl" }, 0);
    defer allocator.free(vert_path);
    const vert = try Shader.init(allocator, vert_path, .vert);
    defer vert.deinit();

    gl.attachShader(id, vert.id);
    defer gl.detachShader(id, vert.id);

    const frag_path = try std.mem.concatWithSentinel(allocator, u8, &.{ prefix, name, "/frag.glsl" }, 0);
    defer allocator.free(frag_path);
    const frag = try Shader.init(allocator, frag_path, .frag);
    defer frag.deinit();
    gl.attachShader(id, frag.id);
    defer gl.detachShader(id, frag.id);

    gl.linkProgram(id);

    // error catching
    var succes: gl.Int = 1;
    gl.getProgramiv(id, gl.LINK_STATUS, &succes);
    if (succes <= 0) {
        var info_log_len: gl.Int = 0;
        gl.getProgramiv(id, gl.INFO_LOG_LENGTH, &info_log_len);
        const info_log = try allocator.alloc(u8, @intCast(info_log_len));
        defer allocator.free(info_log);
        gl.getProgramInfoLog(id, info_log_len, null, info_log.ptr);
        log.err("program {s} failed linkage: {s}", .{ name, info_log });
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
