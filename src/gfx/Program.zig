const std = @import("std");
const log = std.log.scoped(.gfx);
const Allocator = std.mem.Allocator;
const Array = std.ArrayList;

const c = @import("../c.zig");

const Shader = @import("Shader.zig");
const Uniform = @import("Program/Uniform.zig");
const Self = @This();

id: u32,
uniforms: Array(Uniform),

pub fn init(
    shaders: []const Shader,
    uniform_names: []const [:0]const u8,
    allocator: Allocator,
) !Self {
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

    var uniforms = try Array(Uniform).initCapacity(allocator, 8);
    for (uniform_names) |uniform_name| {
        try uniforms.append(try Uniform.init(id, uniform_name));
    }

    const self = Self{ .id = id, .uniforms = uniforms };
    log.debug("init {}", .{self});
    return self;
}

pub fn deinit(self: Self) void {
    log.debug("deinit {}", .{self});
    self.uniforms.deinit();
    c.glDeleteProgram(self.id);
}

pub fn use(self: Self) void {
    c.glUseProgram(self.id);
}
