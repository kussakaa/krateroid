// Модуль для работы с шейдерами OpenGL'а

const c = @import("c.zig");
const std = @import("std");
const print = std.debug.print;
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;
const log_enable = @import("log.zig").shader_log_enable;

pub const Id = u32;
pub const Uniform = i32;
pub const Uniforms = std.ArrayList(Uniform);

pub const Shader = struct {
    pub const Type = enum {
        vertex,
        fragment,
    };

    id: Id, // индекс шейдера

    pub fn initFormFile(allocator: Allocator, shader_path: []const u8, shader_type: Type) !Shader {
        const file = try std.fs.cwd().openFile(shader_path, .{ .mode = .read_only });
        var buffer: [10000]u8 = undefined;
        const bytes_read = try file.readAll(&buffer);
        return Shader.init(allocator, buffer[0..bytes_read], shader_type);
    }

    pub fn init(allocator: Allocator, shader_source: []const u8, shader_type: Type) !Shader {
        const shader = switch (shader_type) {
            Type.vertex => c.glCreateShader(c.GL_VERTEX_SHADER),
            Type.fragment => c.glCreateShader(c.GL_FRAGMENT_SHADER),
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
            const info_log = try allocator.alloc(u8, @as(usize, @intCast(info_log_len)));
            defer allocator.fere(info_log);
            c.glGetShaderInfoLog(shader, info_log_len, null, info_log.ptr);
            panic("\n[!FAILED!]:[SHADER]:[ID:{}]:Compiling: {s}\n", .{ shader, info_log });
        }

        if (log_enable) print("[*SUCCES*]:[SHADER]:[ID:{}]:Compiling\n", .{shader});
        return Shader{
            .id = shader,
        };
    }

    pub fn deinit(self: Shader) void {
        c.glDeleteShader(self.id);
        if (log_enable) print("[*SUCCES*]:[SHADER]:[ID:{}]:Destroyed\n", .{self.id});
    }
};

pub const Program = struct {
    id: Id, // индекс шейдерной программы
    uniforms: Uniforms, // список юниформ программы

    pub fn init(allocator: Allocator, shaders: []const Shader) !Program {
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
            const info_log = try allocator.alloc(u8, @as(usize, @intCast(info_log_len)));
            defer allocator.free(info_log);
            c.glGetProgramInfoLog(program, info_log_len, null, info_log.ptr);
            panic("[!FAILED!]:[SHADER PROGRAM]:[ID:{}]:Linking: {s}\n", .{ program, info_log });
        }

        if (log_enable) print("[*SUCCES*]:[SHADER PROGRAM]:[ID:{}]:Linking\n", .{program});
        return Program{
            .id = program,
            .uniforms = Uniforms.init(allocator),
        };
    }

    pub fn deinit(self: Program) void {
        c.glDeleteProgram(self.id);
        self.uniforms.deinit();
        if (log_enable) print("[*SUCCES*]:[SHADER PROGRAM]:[ID:{}]:Destroyed\n", .{self.id});
    }

    pub fn use(self: Program) void {
        c.glUseProgram(self.id);
    }

    // получение идентификатора юниформы
    pub fn addUniform(self: *Program, name: [*c]const u8) !void {
        const location = @as(i32, @intCast(c.glGetUniformLocation(self.id, name)));
        if (location < 0) {
            panic("[!FAILED!]:[SHADER PROGRAM]:[ID:{}]:Failed finding uniform! {s}\n", .{ self.id, name });
        }
        try self.uniforms.append(location);
    }

    // отправление значение в шейдер по идентификатору юниформы
    pub fn setUniform(self: Program, index: usize, value: anytype) void {
        const uniform = self.uniforms.items[index];
        switch (comptime @TypeOf(value)) {
            f32 => c.glUniform1f(uniform, value),
            comptime_float => c.glUniform1f(uniform, value),
            i32 => c.glUniform1i(uniform, value),
            comptime_int => c.glUniform1i(uniform, value),
            @Vector(3, f32) => {
                const array: [3]f32 = value;
                c.glUniform3fv(uniform, 1, &array);
            },
            @Vector(4, f32) => {
                const array: [4]f32 = value;
                c.glUniform4fv(uniform, 1, &array);
            },
            @Vector(2, i32) => {
                const array: [2]i32 = value;
                c.glUniform2iv(uniform, 1, &array);
            },
            @Vector(3, i32) => {
                const array: [3]i32 = value;
                c.glUniform3iv(uniform, 1, &array);
            },
            @Vector(4, i32) => {
                const array: [4]i32 = value;
                c.glUniform4iv(uniform, 1, &array);
            },
            [4]@Vector(4, f32) => {
                const array = [16]f32{
                    value[0][0], value[1][0], value[2][0], value[3][0],
                    value[0][1], value[1][1], value[2][1], value[3][1],
                    value[0][2], value[1][2], value[2][2], value[3][2],
                    value[0][3], value[1][3], value[2][3], value[3][3],
                };
                c.glUniformMatrix4fv(uniform, 1, c.GL_FALSE, &array);
            },
            else => @compileError("[!FAILED!]:[SHADER PROGRAM]:Incorrect type in setUniform"),
        }
    }
};
