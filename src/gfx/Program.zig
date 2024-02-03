const std = @import("std");
const gl = @import("zopengl");

const log = std.log.scoped(.gfx);
const Allocator = std.mem.Allocator;
const Array = std.ArrayList;
const Shader = @import("Shader.zig");
const Self = @This();

id: gl.Uint,
name: []const u8,

pub fn init(
    allocator: Allocator,
    name: []const u8,
    shaders: []const Shader,
) !Self {
    const id = gl.createProgram();
    for (shaders) |shader| {
        gl.attachShader(id, shader.id);
    }

    // компоновка шейдерной программы
    gl.linkProgram(id);

    // вывод ошибки если программа не скомпоновалась
    var succes: i32 = 1;
    gl.getProgramiv(id, gl.LINK_STATUS, &succes);
    if (succes <= 0) {
        var info_log_len: i32 = 0;
        gl.getProgramiv(id, gl.INFO_LOG_LENGTH, &info_log_len);
        const info_log = try allocator.alloc(u8, @intCast(info_log_len));
        defer allocator.free(info_log);
        gl.getProgramInfoLog(id, info_log_len, null, info_log.ptr);
        log.err(" {} linkage: {s}", .{ id, info_log });
        return error.ShaderProgramLinkage;
    }

    for (shaders) |shader| {
        gl.detachShader(id, shader.id);
    }

    const self = Self{ .name = name, .id = id };
    //log.debug("init {}", .{self});
    return self;
}

pub fn deinit(self: Self) void {
    //log.debug("deinit {}", .{self});
    gl.deleteProgram(self.id);
}

pub fn use(self: Self) void {
    gl.useProgram(self.id);
}
