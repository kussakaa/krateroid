const std = @import("std");
const log = std.log.scoped(.drawer);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;
const c = @import("c.zig");
const window = @import("window.zig");
const gui = @import("gui.zig");

const Vbo = @import("drawer/Vbo.zig");
const Vao = @import("drawer/Vao.zig");
const Ebo = @import("drawer/Ebo.zig");
const Texture = @import("drawer/Texture.zig");
const Shader = @import("drawer/Shader.zig");
const Program = @import("drawer/Program.zig");

const Pos = @Vector(2, i32);
const Size = @Vector(2, i32);

const linmath = @import("linmath.zig");
const Mat = linmath.Mat;
const Vec = linmath.Vec;
const Color = Vec;

var _allocator: Allocator = undefined;
const rect = struct {
    var vbo: Vbo = undefined;
    var vao: Vao = undefined;
    var ebo: Ebo = undefined;
};
const button = struct {
    var program: Program = undefined;
    var empty: Texture = undefined;
    var focus: Texture = undefined;
    var press: Texture = undefined;
};
const text = struct {
    var program: Program = undefined;
    var vbo_pos: Array(Vbo) = undefined;
    var vbo_tex: Array(Vbo) = undefined;
    var vao: Array(Vao) = undefined;
    var ebo: Array(Ebo) = undefined;
    var font: Texture = undefined;
};

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
}) !void {
    _allocator = info.allocator;

    { // прямоугольник
        rect.vbo = try Vbo.init(f32, &.{ 0.0, 0.0, 0.0, -1.0, 1.0, -1.0, 1.0, 0.0 }, .static);
        rect.vao = try Vao.init(&.{
            .{ .size = 2, .vbo = rect.vbo },
        });
        rect.ebo = try Ebo.init(&.{ 0, 1, 3, 2 }, .static);
    }
    { // кнопка
        const vertex = try Shader.initFormFile("core/gui/button/vertex.glsl", .vertex, _allocator);
        const fragment = try Shader.initFormFile("core/gui/button/fragment.glsl", .fragment, _allocator);
        defer vertex.deinit();
        defer fragment.deinit();
        button.program = try Program.init(
            &.{ vertex, fragment },
            &.{ "model", "vpsize", "scale", "rect", "texsize" },
            _allocator,
        );

        button.empty = try Texture.init("core/gui/button/empty.png");
        button.focus = try Texture.init("core/gui/button/focus.png");
        button.press = try Texture.init("core/gui/button/press.png");
    }
    { // текст
        const vertex = try Shader.initFormFile("core/gui/text/vertex.glsl", .vertex, _allocator);
        const fragment = try Shader.initFormFile("core/gui/text/fragment.glsl", .fragment, _allocator);
        defer vertex.deinit();
        defer fragment.deinit();
        text.program = try Program.init(
            &.{ vertex, fragment },
            &.{ "model", "color" },
            _allocator,
        );

        text.vbo_pos = try Array(Vbo).initCapacity(_allocator, 32);
        text.vbo_tex = try Array(Vbo).initCapacity(_allocator, 32);
        text.vao = try Array(Vao).initCapacity(_allocator, 32);
        text.ebo = try Array(Ebo).initCapacity(_allocator, 32);
        text.font = try Texture.init("core/gui/text/font.png");
    }
}

pub fn deinit() void {
    for (text.ebo.items) |item| item.deinit();
    for (text.vao.items) |item| item.deinit();
    for (text.vbo_tex.items) |item| item.deinit();
    for (text.vbo_pos.items) |item| item.deinit();
    text.vbo_pos.deinit(_allocator);
    text.vbo_tex.deinit(_allocator);
    text.vao.deinit(_allocator);
    text.ebo.deinit(_allocator);
    text.program.deinit();

    button.empty.deinit();
    button.focus.deinit();
    button.press.deinit();
    button.program.deinit();

    rect.ebo.deinit();
    rect.vao.deinit();
    rect.vbo.deinit();
}

pub fn draw() !void {
    button.program.use();
    for (gui.buttons.items) |b| {
        const pos = b.alignment.transform(b.rect.scale(gui.scale), window.size).min;
        const size = b.rect.scale(gui.scale).size();
        var matrix = linmath.identity(Mat);
        matrix[0][0] = @as(f32, @floatFromInt(size[0])) / @as(f32, @floatFromInt(window.size[0])) * 2.0;
        matrix[0][3] = @as(f32, @floatFromInt(pos[0])) / @as(f32, @floatFromInt(window.size[0])) * 2.0 - 1.0;
        matrix[1][1] = @as(f32, @floatFromInt(size[1])) / @as(f32, @floatFromInt(window.size[1])) * 2.0;
        matrix[1][3] = @as(f32, @floatFromInt(pos[1])) / @as(f32, @floatFromInt(window.size[1])) * -2.0 + 1.0;

        const texture = switch (b.state) {
            .empty => button.empty,
            .focus => button.focus,
            .press => button.press,
        };
        texture.use();

        button.program.uniform(0, matrix);
        button.program.uniform(1, window.size);
        button.program.uniform(2, gui.scale);
        button.program.uniform(3, b.alignment.transform(b.rect.scale(gui.scale), window.size).vector());
        button.program.uniform(4, texture.size);
        rect.ebo.draw(rect.vao, .triangle_strip);
    }

    text.program.use();
    text.font.use();
    for (gui.texts.items, 0..) |t, i| {
        if (i == text.vao.items.len) {
            const s = struct {
                var vbo_pos_data: [1024]f32 = [1]f32{0.0} ** 1024;
                var vbo_tex_data: [1024]f32 = [1]f32{0.0} ** 1024;
                var ebo_data: [1024]u32 = [1]u32{0} ** 1024;
            };

            var pos: f32 = 0.0;
            var cnt: usize = 0;
            for (t.data) |cid| {
                if (cid == ' ') {
                    pos += 3.0;
                    continue;
                }

                const width = @as(f32, @floatFromInt(gui.font.chars[cid].width));
                const uvpos = @as(f32, @floatFromInt(gui.font.chars[cid].pos)) / @as(f32, @floatFromInt(text.font.size[0]));
                const uvwidth = @as(f32, @floatFromInt(gui.font.chars[cid].width)) / @as(f32, @floatFromInt(text.font.size[0]));

                s.vbo_pos_data[cnt * 8 + 0] = pos; // x
                s.vbo_pos_data[cnt * 8 + 1] = 0.0; // y
                s.vbo_pos_data[cnt * 8 + 2] = pos; // x
                s.vbo_pos_data[cnt * 8 + 3] = -8.0; // y
                s.vbo_pos_data[cnt * 8 + 4] = pos + width; // x
                s.vbo_pos_data[cnt * 8 + 5] = -8.0; // y
                s.vbo_pos_data[cnt * 8 + 6] = pos + width; // x
                s.vbo_pos_data[cnt * 8 + 7] = 0.0; // y

                s.vbo_tex_data[cnt * 8 + 0] = uvpos; // u
                s.vbo_tex_data[cnt * 8 + 1] = 0.0; // v
                s.vbo_tex_data[cnt * 8 + 2] = uvpos; // u
                s.vbo_tex_data[cnt * 8 + 3] = 1.0; // v
                s.vbo_tex_data[cnt * 8 + 4] = uvpos + uvwidth; // u
                s.vbo_tex_data[cnt * 8 + 5] = 1.0; // v
                s.vbo_tex_data[cnt * 8 + 6] = uvpos + uvwidth; // u
                s.vbo_tex_data[cnt * 8 + 7] = 0.0; // v

                s.ebo_data[cnt * 6 + 0] = @intCast(cnt * 4 + 0);
                s.ebo_data[cnt * 6 + 1] = @intCast(cnt * 4 + 1);
                s.ebo_data[cnt * 6 + 2] = @intCast(cnt * 4 + 2);
                s.ebo_data[cnt * 6 + 3] = @intCast(cnt * 4 + 2);
                s.ebo_data[cnt * 6 + 4] = @intCast(cnt * 4 + 3);
                s.ebo_data[cnt * 6 + 5] = @intCast(cnt * 4 + 0);

                pos += width + 1.0;
                cnt += 1;
            }

            const vbo_pos = try Vbo.init(f32, s.vbo_pos_data[0..(cnt * 8)], .static);
            const vbo_tex = try Vbo.init(f32, s.vbo_tex_data[0..(cnt * 8)], .static);
            const vao = try Vao.init(&.{
                .{ .size = 2, .vbo = vbo_pos },
                .{ .size = 2, .vbo = vbo_tex },
            });
            const ebo = try Ebo.init(s.ebo_data[0..(cnt * 6)], .static);

            try text.vbo_pos.append(_allocator, vbo_pos);
            try text.vbo_tex.append(_allocator, vbo_pos);
            try text.vao.append(_allocator, vao);
            try text.ebo.append(_allocator, ebo);
        }

        const pos = t.alignment.transform(t.rect.min * @Vector(2, i32){ gui.scale, gui.scale }, window.size);
        const size = Size{ gui.scale, gui.scale };
        var matrix = linmath.identity(Mat);
        matrix[0][0] = @as(f32, @floatFromInt(size[0])) / @as(f32, @floatFromInt(window.size[0])) * 2.0;
        matrix[0][3] = @as(f32, @floatFromInt(pos[0])) / @as(f32, @floatFromInt(window.size[0])) * 2.0 - 1.0;
        matrix[1][1] = @as(f32, @floatFromInt(size[1])) / @as(f32, @floatFromInt(window.size[1])) * 2.0;
        matrix[1][3] = @as(f32, @floatFromInt(pos[1])) / @as(f32, @floatFromInt(window.size[1])) * -2.0 + 1.0;

        text.program.uniform(0, matrix);
        text.program.uniform(1, Color{ 1.0, 1.0, 1.0, 1.0 });
        text.ebo.items[i].draw(text.vao.items[i], .triangles);
    }
}
