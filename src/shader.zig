// Модуль для работы с шейдерами OpenGL'а

const c = @import("c.zig");
const std = @import("std");
const print = std.debug.print;
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;

pub const ShaderType = enum {
    vertex,
    fragment,
};

pub const Shader = struct {
    id: u32, // индекс шейдера

    pub fn init(allocator: Allocator, shader_source: []const u8, shader_type: ShaderType) !Shader {
        const shader = switch (shader_type) {
            ShaderType.vertex => c.glCreateShader(c.GL_VERTEX_SHADER),
            ShaderType.fragment => c.glCreateShader(c.GL_FRAGMENT_SHADER),
        };

        const shader_source_ptr: ?[*]const u8 = shader_source.ptr;
        c.glShaderSource(shader, 1, &shader_source_ptr, null);
        c.glCompileShader(shader);

        var succes: i32 = 1;
        c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &succes);

        // вывод ошибки если шейдер не скомпилировался
        if (succes == 0) {
            var info_log_len: i32 = 0;
            c.glGetShaderiv(shader, c.GL_INFO_LOG_LENGTH, &info_log_len);
            const info_log = try allocator.alloc(u8, @intCast(usize, info_log_len));
            c.glGetShaderInfoLog(shader, info_log_len, null, info_log.ptr);
            panic("\n[!FAILED!]:[SHADER]:[ID:{}]:Compiling: {s}\n", .{ shader, info_log });
        }

        print("[*SUCCES*]:[SHADER]:[ID:{}]:Compiling\n", .{shader});
        return Shader{
            .id = shader,
        };
    }

    pub fn destroy(self: Shader) void {
        c.glDeleteShader(self.id);
        print("[*SUCCES*]:[SHADER]:[ID:{}]:Destroyed\n", .{self.id});
    }
};

pub const ShaderProgram = struct {
    id: u32, // индекс шейдерной программы

    pub fn init(allocator: Allocator, shaders: []const Shader) !ShaderProgram {
        const program = c.glCreateProgram();
        for (shaders) |shader| {
            c.glAttachShader(program, shader.id);
        }

        // компоновка шейдерной программы
        c.glLinkProgram(program);

        var succes: i32 = 1;
        c.glGetProgramiv(program, c.GL_LINK_STATUS, &succes);

        // вывод ошибки если программа не скомпоновалась
        if (succes == 0) {
            var info_log_len: i32 = 0;
            c.glGetProgramiv(program, c.GL_INFO_LOG_LENGTH, &info_log_len);
            const info_log = try allocator.alloc(u8, @intCast(usize, info_log_len));
            c.glGetProgramInfoLog(program, info_log_len, null, info_log.ptr);
            panic("[!FAILED!]:[SHADER PROGRAM]:[ID:{}]:Linking: {s}\n", .{ program, info_log });
        }

        print("[*SUCCES*]:[SHADER PROGRAM]:[ID:{}]:Linking\n", .{program});
        return ShaderProgram{ .id = program };
    }

    pub fn use(self: ShaderProgram) void {
        c.glUseProgram(self.id);
    }

    // получение идентификатора юниформы
    pub fn getUniform(self: ShaderProgram, name: [*c]const u8) !i32 {
        const location = @intCast(i32, c.glGetUniformLocation(self.id, name));
        if (location < 0) {
            panic("[!FAILED!]:[SHADER PROGRAM]:[ID:{}]:Failed finding uniform! {s}\n", .{ self.id, name });
        }
        return location;
    }

    // отправление значение в шейдер по идентификатору юниформы
    pub fn setUniform(location: i32, value: anytype) void {
        switch (comptime @TypeOf(value)) {
            f32 => c.glUniform1f(location, value),
            comptime_float => c.glUniform1f(location, value),
            i32 => c.glUniform1i(location, value),
            comptime_int => c.glUniform1i(location, value),
            @Vector(3, f32) => {
                const array: [3]f32 = value;
                c.glUniform3fv(location, 1, &array);
            },
            @Vector(4, f32) => {
                const array: [4]f32 = value;
                c.glUniform4fv(location, 1, &array);
            },
            @Vector(2, i32) => {
                const array: [2]i32 = value;
                c.glUniform2iv(location, 1, &array);
            },
            @Vector(3, i32) => {
                const array: [3]i32 = value;
                c.glUniform3iv(location, 1, &array);
            },
            @Vector(4, i32) => {
                const array: [4]i32 = value;
                c.glUniform4iv(location, 1, &array);
            },
            [4]@Vector(4, f32) => {
                const array = [16]f32{
                    value[0][0], value[1][0], value[2][0], value[3][0],
                    value[0][1], value[1][1], value[2][1], value[3][1],
                    value[0][2], value[1][2], value[2][2], value[3][2],
                    value[0][3], value[1][3], value[2][3], value[3][3],
                };
                c.glUniformMatrix4fv(location, 1, c.GL_FALSE, &array);
            },
            else => @compileError("[!FAILED!]:[SHADER PROGRAM]:Incorrect type in setUniform"),
        }
    }

    // уничтожение шейдерной программы
    pub fn destroy(self: ShaderProgram) void {
        c.glDeleteProgram(self.id);
        print("[*SUCCES*]:[SHADER PROGRAM]:[ID:{}]:Destroyed\n", .{self.id});
    }
};
