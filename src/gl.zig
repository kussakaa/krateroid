const c = @import("c.zig");
const std = @import("std");

pub fn getError() !void {
    switch (c.glGetError()) {
        0 => {},
        else => return error.GLError,
    }
}

pub const Mesh = struct {
    vertices: Vertices,
    elements: Elements,

    const Usage = enum(u32) {
        static = c.GL_STATIC_DRAW,
        dynamic = c.GL_DYNAMIC_DRAW,
    };

    const Mode = enum(u32) {
        triangles = c.GL_TRIANGLES,
        lines = c.GL_LINES,
    };

    pub fn draw(self: Mesh) !void {
        try self.elements.draw(self.vertices);
    }

    pub const Vertices = struct {
        vao: u32 = 0, // объект аттрибутов вершин
        vbo: u32 = 0, // объект буфера вершин
        len: u32 = 0, // количество отрисовавыемых вершин
        mode: Mode = .triangles, // Режим отрисовки

        const InitInfo = struct {
            data: []const f32, // массив вершин
            attrs: []const u32, // аттрибуты вершин
            usage: Usage = .static, // режим использования
            mode: Mode = .triangles, // режим отрисовки
        };

        pub fn init(info: InitInfo) !Vertices {
            var vao: u32 = 0;
            var vbo: u32 = 0;

            // создание объекта аттрибутов вершин
            c.glGenVertexArrays(1, &vao);
            c.glBindVertexArray(vao);

            // создание объекта буфера вершин
            c.glCreateBuffers(1, &vbo);
            c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);

            // инициализация данных вершин
            c.glBufferData(
                c.GL_ARRAY_BUFFER,
                @as(c_long, @intCast(info.data.len * @sizeOf(f32))),
                @as(*const anyopaque, &info.data[0]),
                @intFromEnum(info.usage),
            );

            try getError();

            var offset: u32 = 0;
            var vertex_size: u32 = 0;
            for (info.attrs) |i| {
                vertex_size += i;
            }

            // инициализация аттрибутов
            for (info.attrs, 0..) |size, i| {
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

            try getError();

            const vertices = Vertices{
                .vbo = vbo,
                .vao = vao,
                .len = @as(u32, @intCast(info.data.len)) / vertex_size,
                .mode = info.mode,
            };

            std.log.debug("init vertices = {}", .{vertices});
            return vertices;
        }

        pub fn deinit(self: Vertices) void {
            std.log.debug("deinit vertices = {}", .{self});
            c.glDeleteVertexArrays(1, &self.vao);
            c.glDeleteBuffers(1, &self.vbo);
        }

        pub fn subdata(self: Vertices, data: []const f32) !void {
            c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
            c.glBufferSubData(
                c.GL_ARRAY_BUFFER,
                0,
                @as(c_long, @intCast(data.len * @sizeOf(f32))),
                @as(*const anyopaque, &data[0]),
            );
            c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
            try getError();
        }

        pub fn draw(self: Vertices) !void {
            c.glBindVertexArray(self.vao);
            c.glDrawArrays(@intCast(@intFromEnum(self.mode)), 0, @intCast(self.len));
            c.glBindVertexArray(0);
            try getError();
        }
    };

    pub const Elements = struct {
        ebo: u32 = 0, // объект буфера индексов вершин
        len: u32 = 0, // количество отрисовываемых элементов
        mode: Mode = .triangles, // Режим отрисовки

        const InitInfo = struct {
            data: []const u32, // массив индексов
            usage: Usage = .static, // режим использования
            mode: Mode = .triangles, // режим отрисовки
        };

        pub fn init(info: InitInfo) !Elements {
            var ebo: u32 = 0;
            // создание объекта буфера индексов
            c.glCreateBuffers(1, &ebo);
            c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
            c.glBufferData(
                c.GL_ELEMENT_ARRAY_BUFFER,
                @as(c_long, @intCast(info.data.len * @sizeOf(u32))),
                @as(*const anyopaque, &info.data[0]),
                @intFromEnum(info.usage),
            );
            c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, 0);

            try getError();

            const elements = Elements{
                .ebo = ebo,
                .len = @as(u32, @intCast(info.data.len)),
                .mode = info.mode,
            };

            std.log.debug("init elements = {}", .{elements});
            return elements;
        }

        pub fn deinit(self: Elements) void {
            std.log.debug("deinit elements = {}", .{self});
            c.glDeleteBuffers(1, &self.ebo);
        }

        // изменение дынных буфера (не выделение памяти)
        pub fn subdata(self: Elements, data: []const u32) !void {
            c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
            c.glBufferSubData(
                c.GL_ELEMENT_ARRAY_BUFFER,
                0,
                @as(c_long, @intCast(data.len * @sizeOf(f32))),
                @as(*const anyopaque, &data[0]),
            );
            c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, 0);
            try getError();
        }

        pub fn draw(self: Elements, vertices: Vertices) !void {
            c.glBindVertexArray(vertices.vao);
            c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
            c.glDrawElements(@intCast(@intFromEnum(self.mode)), @intCast(self.len), c.GL_UNSIGNED_INT, null);
            c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, 0);
            c.glBindVertexArray(0);
            try getError();
        }
    };
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

    id: u32, // индекс шейдерной программы
    uniforms: [16]Uniform, // список юниформ программы

    pub fn init(allocator: std.mem.Allocator, shaders: []const Shader, comptime uniform_names: []const [*c]const u8) !Program {
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
            const info_log = try allocator.alloc(u8, @as(usize, @intCast(info_log_len)));
            defer allocator.free(info_log);
            c.glGetProgramInfoLog(id, info_log_len, null, info_log.ptr);
            std.log.err("program {} linkage: {s}", .{ id, info_log });
            return error.ShaderProgramLinkage;
        }

        for (shaders) |shader| {
            c.glDetachShader(id, shader.id);
        }

        var uniforms: [16]Uniform = [1]Uniform{0} ** 16;
        for (uniform_names, 0..) |name, i| {
            const location = @as(i32, @intCast(c.glGetUniformLocation(id, name)));
            if (location < 0) {
                std.log.err("failed finding uniform {s} in program {}", .{ name, id });
                return error.UniformNotFound;
            }
            uniforms[i] = location;
        }

        const program = Program{ .id = id, .uniforms = uniforms };
        std.log.debug("init shader program = {}", .{program});
        return program;
    }

    pub fn deinit(self: Program) void {
        std.log.debug("deinit shader program = {}", .{self});
        c.glDeleteProgram(self.id);
    }

    pub fn use(self: Program) void {
        c.glUseProgram(self.id);
    }

    // отправление значение в шейдер по идентификатору юниформы
    pub fn setUniform(self: Program, index: usize, value: anytype) void {
        const uniform = self.uniforms[index];
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
