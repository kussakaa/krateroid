const std = @import("std");
const log = std.log.scoped(.ShaderProgram);
const Allocator = std.mem.Allocator;
const c = @import("../c.zig");

const Shader = @import("Shader.zig");
const Program = @This();
const Uniform = i32;

id: u32, // индекс шейдерной программы
uniforms: [16]Uniform, // список юниформ программы

pub fn init(
    shaders: []const Shader,
    comptime uniform_names: []const [*c]const u8,
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

    var uniforms: [16]Uniform = [1]Uniform{0} ** 16;
    for (uniform_names, 0..) |name, i| {
        uniforms[i] = @intCast(c.glGetUniformLocation(id, name));
    }

    const program = Program{ .id = id, .uniforms = uniforms };
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

// отправление значение в шейдер по идентификатору юниформы
pub fn uniform(self: Program, index: usize, value: anytype) void {
    const id = self.uniforms[index];
    switch (comptime @TypeOf(value)) {
        f32 => c.glUniform1f(id, value),
        comptime_float => c.glUniform1f(id, value),
        i32 => c.glUniform1i(id, value),
        comptime_int => c.glUniform1i(id, value),
        @Vector(3, f32) => {
            const array: [3]f32 = value;
            c.glUniform3fv(id, 1, &array);
        },
        @Vector(4, f32) => {
            const array: [4]f32 = value;
            c.glUniform4fv(id, 1, &array);
        },
        @Vector(2, i32) => {
            const array: [2]i32 = value;
            c.glUniform2iv(id, 1, &array);
        },
        @Vector(3, i32) => {
            const array: [3]i32 = value;
            c.glUniform3iv(id, 1, &array);
        },
        @Vector(4, i32) => {
            const array: [4]i32 = value;
            c.glUniform4iv(id, 1, &array);
        },
        [4]@Vector(4, f32) => {
            const array = [16]f32{
                value[0][0], value[1][0], value[2][0], value[3][0],
                value[0][1], value[1][1], value[2][1], value[3][1],
                value[0][2], value[1][2], value[2][2], value[3][2],
                value[0][3], value[1][3], value[2][3], value[3][3],
            };
            c.glUniformMatrix4fv(id, 1, c.GL_FALSE, &array);
        },
        else => @compileError("invalid type uniform"),
    }
}
