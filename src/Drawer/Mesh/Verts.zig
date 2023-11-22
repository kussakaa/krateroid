const std = @import("std");
const log = std.log.scoped(.GameDrawerMeshVerts);
const c = @import("../../c.zig");

fn glGetError() !void {
    switch (c.glGetError()) {
        0 => {},
        else => return error.GLError,
    }
}

const Usage = enum(u32) {
    static = c.GL_STATIC_DRAW,
    dynamic = c.GL_DYNAMIC_DRAW,
};

const Mode = enum(u32) {
    triangles = c.GL_TRIANGLES,
    lines = c.GL_LINES,
};

const Verts = @This();
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

pub fn init(info: InitInfo) !Verts {
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

    try glGetError();

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

    try glGetError();

    const vertices = Verts{
        .vbo = vbo,
        .vao = vao,
        .len = @as(u32, @intCast(info.data.len)) / vertex_size,
        .mode = info.mode,
    };

    log.debug("init {}", .{vertices});
    return vertices;
}

pub fn deinit(self: Verts) void {
    log.debug("deinit  {}", .{self});
    c.glDeleteVertexArrays(1, &self.vao);
    c.glDeleteBuffers(1, &self.vbo);
}

pub fn subdata(self: Verts, data: []const f32) !void {
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
    c.glBufferSubData(
        c.GL_ARRAY_BUFFER,
        0,
        @as(c_long, @intCast(data.len * @sizeOf(f32))),
        @as(*const anyopaque, &data[0]),
    );
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    try glGetError();
}

pub fn draw(self: Verts) !void {
    c.glBindVertexArray(self.vao);
    c.glDrawArrays(@intCast(@intFromEnum(self.mode)), 0, @intCast(self.len));
    c.glBindVertexArray(0);
    try glGetError();
}
