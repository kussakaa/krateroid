const std = @import("std");
const log = std.log.scoped(.drawer);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;
const c = @import("c.zig");
const window = @import("window.zig");
const gui = @import("gui.zig");

const Vbo = @import("gfx/Vbo.zig");
const Vao = @import("gfx/Vao.zig");
const Ebo = @import("gfx/Ebo.zig");
const Texture = @import("gfx/Texture.zig");
const Shader = @import("gfx/Shader.zig");
const Program = @import("gfx/Program.zig");
const Uniform = @import("gfx/Uniform.zig");

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
    const uniform = struct {
        var vpsize: Uniform = undefined;
        var scale: Uniform = undefined;
        var rect: Uniform = undefined;
    };
    const texture = struct {
        var empty: Texture = undefined;
        var focus: Texture = undefined;
        var press: Texture = undefined;
    };
};
const text = struct {
    var program: Program = undefined;
    const uniform = struct {
        var vpsize: Uniform = undefined;
        var scale: Uniform = undefined;
        var pos: Uniform = undefined;
        var color: Uniform = undefined;
    };
    var texture: Texture = undefined;
    var vbo_pos: Array(Vbo) = undefined;
    var vbo_tex: Array(Vbo) = undefined;
    var vao: Array(Vao) = undefined;
    var ebo: Array(Ebo) = undefined;
};

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
}) !void {
    _allocator = info.allocator;

    { // прямоугольник
        rect.vbo = try Vbo.init(u8, &.{ 0, 0, 0, 1, 1, 0, 1, 1 }, .static);
        rect.vao = try Vao.init(&.{
            .{ .size = 2, .vbo = rect.vbo },
        });
        rect.ebo = try Ebo.init(u8, &.{ 0, 1, 2, 3 }, .static);
    }
    { // кнопка
        const vertex = try Shader.initFormFile("core/gui/button/vertex.glsl", .vertex, _allocator);
        const fragment = try Shader.initFormFile("core/gui/button/fragment.glsl", .fragment, _allocator);
        defer vertex.deinit();
        defer fragment.deinit();
        button.program = try Program.init(
            &.{ vertex, fragment },
            _allocator,
        );
        button.uniform.vpsize = try Uniform.init(button.program, "vpsize");
        button.uniform.scale = try Uniform.init(button.program, "scale");
        button.uniform.rect = try Uniform.init(button.program, "rect");

        button.texture.empty = try Texture.init("core/gui/button/empty.png");
        button.texture.focus = try Texture.init("core/gui/button/focus.png");
        button.texture.press = try Texture.init("core/gui/button/press.png");
    }
    { // текст
        const vertex = try Shader.initFormFile("core/gui/text/vertex.glsl", .vertex, _allocator);
        const fragment = try Shader.initFormFile("core/gui/text/fragment.glsl", .fragment, _allocator);
        defer vertex.deinit();
        defer fragment.deinit();
        text.program = try Program.init(
            &.{ vertex, fragment },
            _allocator,
        );

        text.uniform.vpsize = try Uniform.init(text.program, "vpsize");
        text.uniform.scale = try Uniform.init(text.program, "scale");
        text.uniform.pos = try Uniform.init(text.program, "pos");
        text.uniform.color = try Uniform.init(text.program, "color");

        text.texture = try Texture.init("core/gui/text/font.png");

        text.vbo_pos = try Array(Vbo).initCapacity(_allocator, 32);
        text.vbo_tex = try Array(Vbo).initCapacity(_allocator, 32);
        text.vao = try Array(Vao).initCapacity(_allocator, 32);
        text.ebo = try Array(Ebo).initCapacity(_allocator, 32);
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

    button.texture.empty.deinit();
    button.texture.focus.deinit();
    button.texture.press.deinit();
    button.program.deinit();

    rect.ebo.deinit();
    rect.vao.deinit();
    rect.vbo.deinit();
}

pub fn draw() !void {
    button.program.use();
    for (gui.buttons.items) |b| {
        switch (b.state) {
            .empty => button.texture.empty.use(),
            .focus => button.texture.focus.use(),
            .press => button.texture.press.use(),
        }
        button.uniform.vpsize.set(window.size);
        button.uniform.scale.set(gui.scale);
        button.uniform.rect.set(b.alignment.transform(b.rect.scale(gui.scale), window.size).vector());
        rect.ebo.draw(rect.vao, .triangle_strip);
    }

    text.program.use();
    text.texture.use();
    for (gui.texts.items, 0..) |t, i| {
        if (i == text.vao.items.len) {
            const s = struct {
                var vbo_pos_data: [1024]u16 = [1]u16{0} ** 1024;
                var vbo_tex_data: [1024]u16 = [1]u16{0} ** 1024;
                var ebo_data: [1024]u16 = [1]u16{0} ** 1024;
            };

            var pos: u16 = 0;
            var cnt: usize = 0;
            for (t.data) |cid| {
                if (cid == ' ') {
                    pos += 3;
                    continue;
                }

                const width = gui.font.chars[cid].width;
                const uvpos = gui.font.chars[cid].pos;
                const uvwidth = gui.font.chars[cid].width;

                s.vbo_pos_data[cnt * 8 + 0] = pos; // x
                s.vbo_pos_data[cnt * 8 + 1] = 0; // y
                s.vbo_pos_data[cnt * 8 + 2] = pos; // x
                s.vbo_pos_data[cnt * 8 + 3] = 8; // y
                s.vbo_pos_data[cnt * 8 + 4] = pos + width; // x
                s.vbo_pos_data[cnt * 8 + 5] = 8; // y
                s.vbo_pos_data[cnt * 8 + 6] = pos + width; // x
                s.vbo_pos_data[cnt * 8 + 7] = 0; // y

                s.vbo_tex_data[cnt * 4 + 0] = uvpos; // u
                s.vbo_tex_data[cnt * 4 + 1] = uvpos; // u
                s.vbo_tex_data[cnt * 4 + 2] = uvpos + uvwidth; // u
                s.vbo_tex_data[cnt * 4 + 3] = uvpos + uvwidth; // u

                s.ebo_data[cnt * 6 + 0] = @intCast(cnt * 4 + 0);
                s.ebo_data[cnt * 6 + 1] = @intCast(cnt * 4 + 1);
                s.ebo_data[cnt * 6 + 2] = @intCast(cnt * 4 + 2);
                s.ebo_data[cnt * 6 + 3] = @intCast(cnt * 4 + 2);
                s.ebo_data[cnt * 6 + 4] = @intCast(cnt * 4 + 3);
                s.ebo_data[cnt * 6 + 5] = @intCast(cnt * 4 + 0);

                pos += width + 1;
                cnt += 1;
            }

            const vbo_pos = try Vbo.init(u16, s.vbo_pos_data[0..(cnt * 8)], .static);
            const vbo_tex = try Vbo.init(u16, s.vbo_tex_data[0..(cnt * 8)], .static);
            const vao = try Vao.init(&.{
                .{ .size = 2, .vbo = vbo_pos },
                .{ .size = 1, .vbo = vbo_tex },
            });
            const ebo = try Ebo.init(u16, s.ebo_data[0..(cnt * 6)], .static);

            try text.vbo_pos.append(_allocator, vbo_pos);
            try text.vbo_tex.append(_allocator, vbo_pos);
            try text.vao.append(_allocator, vao);
            try text.ebo.append(_allocator, ebo);
        }

        const pos = t.alignment.transform(t.rect.min * @Vector(2, i32){ gui.scale, gui.scale }, window.size);

        text.uniform.vpsize.set(window.size);
        text.uniform.scale.set(gui.scale);
        text.uniform.pos.set(pos);
        text.uniform.color.set(Color{ 1.0, 1.0, 1.0, 1.0 });
        text.ebo.items[i].draw(text.vao.items[i], .triangles);
    }
}
