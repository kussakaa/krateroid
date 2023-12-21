const std = @import("std");
const log = std.log.scoped(.ShaderProgram);
const Allocator = std.mem.Allocator;
const c = @import("../c.zig");

const Shader = @import("Shader.zig");
const Program = @This();

id: u32,

pub fn init(
    shaders: []const Shader,
    allocator: Allocator,
) !Program {
    const id = c.glCreateProgram();
    for (shaders) |shader| {
        c.glAttachShader(id, shader.id);
    }
    // компоновка шейдерной программы
    c.glLinkProgram(id);

    // вывод ошибки если программа не скомпоновалась
    var succes: i32 = 1;
    c.glGetProgramiv(id, c.GL_LINK_STATUS, &succes);
    if (succes <= 0) {
        var info_log_len: i32 = 0;
        c.glGetProgramiv(id, c.GL_INFO_LOG_LENGTH, &info_log_len);
        const info_log = try allocator.alloc(u8, @intCast(info_log_len));
        defer allocator.free(info_log);
        c.glGetProgramInfoLog(id, info_log_len, null, info_log.ptr);
        log.err(" {} linkage: {s}", .{ id, info_log });
        return error.ShaderProgramLinkage;
    }

    for (shaders) |shader| {
        c.glDetachShader(id, shader.id);
    }

    const program = Program{ .id = id };
    log.debug("init {}", .{program});
    return program;
}

pub fn deinit(self: Program) void {
    log.debug("deinit {}", .{self});
    c.glDeleteProgram(self.id);
}

pub fn use(self: Program) void {
    c.glUseProgram(self.id);
}
