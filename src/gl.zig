const c = @import("c.zig");
const std = @import("std");

pub const Mesh = struct {
    vbo: u32, // Объект буфера вершин
    vao: u32, // Объект аттрибутов вершин
    len: usize, // Количество вершин
    params: Params,

    const Params = struct {
        usage: enum {
            static,
            dynamic,
        } = .static,
        mode: enum {
            triangles,
            lines,
        } = .triangles,
    };

    pub fn init(vertices: []const f32, attrs: []const u32, params: Params) !Mesh {
        var vertex_size: u32 = 0;
        for (attrs) |i| {
            vertex_size += i;
        }

        var vao: u32 = 0;
        c.glGenVertexArrays(1, &vao);
        if (vao < 0) {
            std.log.err("failed VAO generate");
            return error.GenerateVAO;
        }
        c.glBindVertexArray(vao);

        var vbo: u32 = 0;
        c.glCreateBuffers(1, &vbo);
        if (vbo < 0) {
            std.log.err("failed VBO create");
            return error.CreateVBO;
        }
        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBufferData(
            c.GL_ARRAY_BUFFER,
            @as(c_long, @intCast(vertices.len * @sizeOf(f32))),
            @as(*const anyopaque, &vertices[0]),
            switch (params.usage) {
                .static => c.GL_STATIC_DRAW,
                .dynamic => c.GL_STATIC_DRAW,
            },
        );

        var offset: u32 = 0;
        for (attrs, 0..) |_, i| {
            const size = attrs[i];
            c.glVertexAttribPointer(
                @as(c_uint, @intCast(i)),
                @as(c_int, @intCast(size)),
                c.GL_FLOAT,
                c.GL_FALSE,
                @as(c_int, @intCast(vertex_size * @sizeOf(f32))),
                @as(?*anyopaque, @ptrFromInt(offset * @sizeOf(f32))),
            );
            c.glEnableVertexAttribArray(@as(c_uint, @intCast(i)));
            offset += size;
        }

        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
        c.glBindVertexArray(0);

        const mesh = Mesh{
            .vbo = vbo,
            .vao = vao,
            .len = vertices.len / vertex_size,
            .params = params,
        };
        std.log.debug("init mesh = {}", .{mesh});
        return mesh;
    }

    pub fn deinit(self: Mesh) void {
        std.log.debug("deinit mesh = {}", .{self});
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
    }

    pub fn subData(self: Mesh) !void {
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glBufferSubData(c.GL_ARRAY_BUFFER);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    }

    pub fn draw(self: Mesh) void {
        c.glBindVertexArray(self.vao);
        const mode = switch (self.params.mode) {
            .triangles => c.GL_TRIANGLES,
            .lines => c.GL_LINES,
        };
        c.glDrawArrays(@intCast(mode), 0, @as(i32, @intCast(self.len)));
        c.glBindVertexArray(0);
    }
};

pub const Texture = struct {
    id: u32 = 0,
    size: @Vector(2, i32),
    channels: i32,

    pub fn init(path: []const u8) !Texture {
        var width: i32 = 0;
        var height: i32 = 0;
        var channels: i32 = 0;
        const data = c.stbi_load(path.ptr, &width, &height, &channels, 0);

        if (data == null) {
            std.log.err("failed image upload in path {s}", .{path});
            return error.ImageUpload;
        }

        var id: u32 = 0;

        c.glGenTextures(1, &id);
        c.glBindTexture(c.GL_TEXTURE_2D, id);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
        const format = switch (channels) {
            1 => c.GL_RED,
            3 => c.GL_RGB,
            4 => c.GL_RGBA,
            else => {
                std.log.err("invalid channels count {} in texture", .{channels});
                return error.ChannelsCount;
            },
        };

        c.glTexImage2D(c.GL_TEXTURE_2D, 0, @intCast(format), width, height, 0, @intCast(format), c.GL_UNSIGNED_BYTE, data);
        c.glBindTexture(c.GL_TEXTURE_2D, 0);
        c.stbi_image_free(data);

        const texture = Texture{
            .id = id,
            .size = .{ width, height },
            .channels = channels,
        };
        std.log.debug("init texture = {}", .{texture});
        return texture;
    }
    pub fn deinit(self: Texture) void {
        std.log.debug("deinit texture = {}", .{self});
        c.glDeleteTextures(1, &self.id);
    }

    pub fn use(self: Texture) void {
        c.glBindTexture(c.GL_TEXTURE_2D, self.id);
    }
};

pub const Shader = struct {
    pub const Type = enum {
        vertex,
        fragment,
    };

    id: u32, // индекс шейдера

    pub fn initFormFile(allocator: std.mem.Allocator, shader_path: []const u8, shader_type: Type) !Shader {
        const file = try std.fs.cwd().openFile(shader_path, .{ .mode = .read_only });
        var buffer: [10000]u8 = undefined;
        const bytes_read = try file.readAll(&buffer);
        return Shader.init(allocator, buffer[0..bytes_read], shader_type);
    }

    pub fn init(allocator: std.mem.Allocator, shader_source: []const u8, shader_type: Type) !Shader {
        const id = switch (shader_type) {
            Type.vertex => c.glCreateShader(c.GL_VERTEX_SHADER),
            Type.fragment => c.glCreateShader(c.GL_FRAGMENT_SHADER),
        };

        const shader_source_ptr: ?[*]const u8 = shader_source.ptr;
        c.glShaderSource(id, 1, &shader_source_ptr, null);
        c.glCompileShader(id);

        var succes: i32 = 1;
        c.glGetShaderiv(id, c.GL_COMPILE_STATUS, &succes);

        // вывод ошибки если шейдер не скомпилировался
        if (succes == 0) {
            var info_log_len: i32 = 0;
            c.glGetShaderiv(id, c.GL_INFO_LOG_LENGTH, &info_log_len);
            const info_log = try allocator.alloc(u8, @as(usize, @intCast(info_log_len)));
            defer allocator.free(info_log);
            c.glGetShaderInfoLog(id, info_log_len, null, info_log.ptr);
            std.log.err("shader {} compilation: <r>{s}\n", .{ id, info_log });
            return error.ShaderCompilation;
        }

        const shader = Shader{ .id = id };
        std.log.debug("init shader = {}", .{shader});
        return shader;
    }

    pub fn deinit(self: Shader) void {
        std.log.debug("deinit shader = {}", .{self});
        c.glDeleteShader(self.id);
    }
};

pub const Program = struct {
    pub const Uniform = i32;
    pub const Uniforms = std.ArrayList(Uniform);

    id: u32, // индекс шейдерной программы
    uniforms: Uniforms, // список юниформ программы

    pub fn init(allocator: std.mem.Allocator, shaders: []const Shader) !Program {
        const id = c.glCreateProgram();
        for (shaders) |shader| {
            c.glAttachShader(id, shader.id);
        }

        // компоновка шейдерной программы
        c.glLinkProgram(id);

        var succes: i32 = 1;
        c.glGetProgramiv(id, c.GL_LINK_STATUS, &succes);

        // вывод ошибки если программа не скомпоновалась
        if (succes == 0) {
            var info_log_len: i32 = 0;
            c.glGetProgramiv(id, c.GL_INFO_LOG_LENGTH, &info_log_len);
            const info_log = try allocator.alloc(u8, @as(usize, @intCast(info_log_len)));
            defer allocator.free(info_log);
            c.glGetProgramInfoLog(id, info_log_len, null, info_log.ptr);
            std.log.err("program {} linkage: {s}", .{ id, info_log });
            return error.ShaderProgramLinkage;
        }

        const program = Program{ .id = id, .uniforms = Uniforms.init(allocator) };
        std.log.debug("init shader program = {}", .{program});
        return program;
    }

    pub fn deinit(self: Program) void {
        std.log.debug("deinit shader program = {}", .{self});
        c.glDeleteProgram(self.id);
        self.uniforms.deinit();
    }

    pub fn use(self: Program) void {
        c.glUseProgram(self.id);
    }

    // получение идентификатора юниформы
    pub fn addUniform(self: *Program, name: [*c]const u8) !void {
        const location = @as(i32, @intCast(c.glGetUniformLocation(self.id, name)));
        if (location < 0) {
            std.log.warn("failed finding uniform {s} in program {}", .{ name, self });
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
            else => @compileError("invalid type uniform"),
        }
    }
};
