id: Id,
name: []const u8,

pub const Config = struct {
    name: []const u8,
};

pub fn init(allocator: Allocator, config: Config) anyerror!Self {
    const name = config.name;
    const id = gl.createProgram();

    const vert = try Shader.init(allocator, .{
        .name = name,
        .shader_type = .vert,
    });
    defer vert.deinit();
    gl.attachShader(id, vert.id);
    defer gl.detachShader(id, vert.id);

    const frag = try Shader.init(allocator, .{
        .name = name,
        .shader_type = .frag,
    });
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
        const info_log_data = try allocator.alloc(u8, @intCast(info_log_len));
        gl.getProgramInfoLog(id, info_log_len, null, info_log_data[0..].ptr);
        log.failed(.init, "GFX Program name:{s} id: {}\n{s}", .{ name, id, info_log_data[0..] });
        return Error.Linkage;
    }

    log.succes(.init, "GFX Program name:{s} id:{}", .{ name, id });

    return .{ .id = id, .name = name };
}

pub fn deinit(self: Self) void {
    gl.deleteProgram(self.id);
}

pub fn use(self: Self) void {
    gl.useProgram(self.id);
}

const Self = @This();

pub const Id = gl.Uint;

pub const Error = error{Linkage};

const Allocator = std.mem.Allocator;
const Shader = @import("Shader.zig");

const std = @import("std");
const log = @import("log");

const gl = @import("zopengl").bindings;
