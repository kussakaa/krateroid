const c = @import("c.zig");
const print = @import("std").debug.print;

pub const Mesh = struct {
    vbo: u32, // Объект буфера вершин
    vao: u32, // Объект аттрибутов вершин
    len: usize, // Количество вершин

    pub fn create(vertices: []const f32, attrs: []const u32) Mesh {
        var vertex_size: u32 = 0;
        for (attrs) |i| {
            vertex_size += i;
        }

        var vao: u32 = undefined;
        c.glGenVertexArrays(1, &vao);
        c.glBindVertexArray(vao);

        var vbo: u32 = undefined;
        c.glCreateBuffers(1, &vbo);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBufferData(
            c.GL_ARRAY_BUFFER,
            @intCast(c_long, vertices.len * @sizeOf(f32)),
            @as(*const anyopaque, &vertices[0]),
            c.GL_STATIC_DRAW,
        );

        var offset: u32 = 0;
        for (attrs) |_, i| {
            const size = attrs[i];
            c.glVertexAttribPointer(
                @intCast(c_uint, i),
                @intCast(c_int, size),
                c.GL_FLOAT,
                c.GL_FALSE,
                @intCast(c_int, vertex_size * @sizeOf(f32)),
                @intToPtr(?*anyopaque, offset * @sizeOf(f32)),
            );
            c.glEnableVertexAttribArray(@intCast(c_uint, i));
            offset += size;
        }

        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
        c.glBindVertexArray(0);

        print("[СОЗДАН]:Сетка полигонов[Вершин:{}|VBO:{}|VAO:{}]\n", .{ vertices.len / vertex_size, vbo, vao });
        return Mesh{
            .vbo = vbo,
            .vao = vao,
            .len = vertices.len / vertex_size,
        };
    }

    pub fn draw(self: Mesh) void {
        c.glBindVertexArray(self.vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, @intCast(i32, self.len));
        c.glBindVertexArray(0);
    }

    pub fn delete(self: Mesh) void {
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
        print("[УДАЛЁН]:Сетка полигонов[Вершин:{}|VBO:{}|VAO:{}]\n", .{ self.len, self.vbo, self.vao });
    }
};
