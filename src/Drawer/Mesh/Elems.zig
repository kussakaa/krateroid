const std = @import("std");
const log = std.log.scoped(.GameDrawerMeshElems);
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

const Verts = @import("Verts.zig");
const Elems = @This();

ebo: u32 = 0, // объект буфера индексов вершин
len: u32 = 0, // количество отрисовываемых элементов
mode: Mode = .triangles, // Режим отрисовки

pub const InitInfo = struct {
    data: []const u32, // массив индексов
    usage: Usage = .static, // режим использования
    mode: Mode = .triangles, // режим отрисовки
};

pub fn init(info: InitInfo) !Elems {
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

    try glGetError();

    const elements = Elems{
        .ebo = ebo,
        .len = @as(u32, @intCast(info.data.len)),
        .mode = info.mode,
    };

    log.debug("init  {}", .{elements});
    return elements;
}

pub fn deinit(self: Elems) void {
    log.debug("deinit {}", .{self});
    c.glDeleteBuffers(1, &self.ebo);
}

// изменение дынных буфера (не выделение памяти)
pub fn subdata(self: Elems, data: []const u32) !void {
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
    c.glBufferSubData(
        c.GL_ELEMENT_ARRAY_BUFFER,
        0,
        @as(c_long, @intCast(data.len * @sizeOf(f32))),
        @as(*const anyopaque, &data[0]),
    );
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, 0);
    try glGetError();
}

pub fn draw(self: Elems, vertices: Verts) !void {
    c.glBindVertexArray(vertices.vao);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
    c.glDrawElements(@intCast(@intFromEnum(self.mode)), @intCast(self.len), c.GL_UNSIGNED_INT, null);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);
    try glGetError();
}
