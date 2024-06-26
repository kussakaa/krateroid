id: Id,
name: []const u8,

pub fn init(config: Config) !Self {
    const allocator = config.allocator;
    const name = config.name;

    const id = gl.createProgram();

    const vert = try Shader.init(.{
        .allocator = allocator,
        .name = name,
        .shader_type = .vert,
    });
    defer vert.deinit();
    gl.attachShader(id, vert.id);
    defer gl.detachShader(id, vert.id);

    const frag = try Shader.init(.{
        .allocator = allocator,
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
        log.err("Failed {s} linkage: {s}", .{ name, info_log_data[0..] });
        return error.ShaderProgramLinkage;
    }

    log.info("Initialization {s}{s}competed{s} {s}name:{s}{s} {s}id:{s}{}", .{
        TermColor(null).bold(),
        TermColor(.fg).bit(2),
        TermColor(null).reset(),
        TermColor(.fg).bit(4),
        TermColor(.fg).reset(),
        name,
        TermColor(.fg).bit(4),
        TermColor(null).reset(),
        id,
    });

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
pub const Config = struct {
    allocator: Allocator = std.heap.page_allocator,
    name: []const u8,
};

const Allocator = std.mem.Allocator;
const Shader = @import("Shader.zig");

const TermColor = @import("terminal").Color;

const std = @import("std");
const log = std.log.scoped(.Gfx_Program);
const gl = @import("zopengl").bindings;
