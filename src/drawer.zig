const std = @import("std");
const log = std.log.scoped(.drawer);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;
const c = @import("c.zig");
const window = @import("window.zig");
const gui = @import("gui.zig");
const world = @import("world.zig");

const util = struct {
    usingnamespace @import("gfx/util.zig");
};
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
const Mat4 = linmath.Mat(4);
const Vec4 = linmath.Vec(4);
const Color = Vec4;

var allocator: Allocator = undefined;
const data = struct {
    const gui = struct {
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
            var vbo: Vbo = undefined;
            var vao: Vao = undefined;
            var ebo: Ebo = undefined;
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
    };
    //const world = struct {
    //    var program: Program = undefined;
    //};
};

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
}) !void {
    allocator = info.allocator;

    { // кнопка
        const vertex = try Shader.initFormFile("data/gui/button/vertex.glsl", .vertex, allocator);
        const fragment = try Shader.initFormFile("data/gui/button/fragment.glsl", .fragment, allocator);
        defer vertex.deinit();
        defer fragment.deinit();
        data.gui.button.program = try Program.init(&.{ vertex, fragment }, allocator);
        data.gui.button.uniform.vpsize = try Uniform.init(data.gui.button.program, "vpsize");
        data.gui.button.uniform.scale = try Uniform.init(data.gui.button.program, "scale");
        data.gui.button.uniform.rect = try Uniform.init(data.gui.button.program, "rect");
        data.gui.button.texture.empty = try Texture.init("data/gui/button/empty.png");
        data.gui.button.texture.focus = try Texture.init("data/gui/button/focus.png");
        data.gui.button.texture.press = try Texture.init("data/gui/button/press.png");
        data.gui.button.vbo = try Vbo.init(u8, &.{ 0, 0, 0, 1, 1, 0, 1, 1 }, .static);
        data.gui.button.vao = try Vao.init(&.{.{ .size = 2, .vbo = data.gui.button.vbo }});
        data.gui.button.ebo = try Ebo.init(u8, &.{ 0, 1, 2, 3 }, .static);
    }
    { // текст
        const vertex = try Shader.initFormFile("data/gui/text/vertex.glsl", .vertex, allocator);
        const fragment = try Shader.initFormFile("data/gui/text/fragment.glsl", .fragment, allocator);
        defer vertex.deinit();
        defer fragment.deinit();
        data.gui.text.program = try Program.init(&.{ vertex, fragment }, allocator);
        data.gui.text.uniform.vpsize = try Uniform.init(data.gui.text.program, "vpsize");
        data.gui.text.uniform.scale = try Uniform.init(data.gui.text.program, "scale");
        data.gui.text.uniform.pos = try Uniform.init(data.gui.text.program, "pos");
        data.gui.text.uniform.color = try Uniform.init(data.gui.text.program, "color");
        data.gui.text.texture = try Texture.init("data/gui/text/font.png");
        data.gui.text.vbo_pos = try Array(Vbo).initCapacity(allocator, 32);
        data.gui.text.vbo_tex = try Array(Vbo).initCapacity(allocator, 32);
        data.gui.text.vao = try Array(Vao).initCapacity(allocator, 32);
        data.gui.text.ebo = try Array(Ebo).initCapacity(allocator, 32);
    }
}

pub fn deinit() void {
    for (data.gui.text.ebo.items) |item| item.deinit();
    for (data.gui.text.vao.items) |item| item.deinit();
    for (data.gui.text.vbo_tex.items) |item| item.deinit();
    for (data.gui.text.vbo_pos.items) |item| item.deinit();
    data.gui.text.vbo_pos.deinit(allocator);
    data.gui.text.vbo_tex.deinit(allocator);
    data.gui.text.vao.deinit(allocator);
    data.gui.text.ebo.deinit(allocator);
    data.gui.text.program.deinit();

    data.gui.button.ebo.deinit();
    data.gui.button.vao.deinit();
    data.gui.button.vbo.deinit();
    data.gui.button.texture.empty.deinit();
    data.gui.button.texture.focus.deinit();
    data.gui.button.texture.press.deinit();
    data.gui.button.program.deinit();
}

pub fn draw() !void {
    // gui
    data.gui.button.program.use();
    for (gui.buttons.items) |b| {
        switch (b.state) {
            .empty => data.gui.button.texture.empty.use(),
            .focus => data.gui.button.texture.focus.use(),
            .press => data.gui.button.texture.press.use(),
        }
        data.gui.button.uniform.vpsize.set(window.size);
        data.gui.button.uniform.scale.set(gui.scale);
        data.gui.button.uniform.rect.set(b.alignment.transform(b.rect.scale(gui.scale), window.size).vector());
        data.gui.button.ebo.draw(data.gui.button.vao, .triangle_strip);
    }

    data.gui.text.program.use();
    data.gui.text.texture.use();
    for (gui.texts.items, 0..) |t, i| {
        if (i == data.gui.text.vao.items.len or t.usage == .dynamic) {
            const s = struct {
                var vbo_pos_data: [1024]u16 = [1]u16{0} ** 1024;
                var vbo_tex_data: [512]u16 = [1]u16{0} ** 512;
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

            if (i == data.gui.text.vao.items.len) {
                const usage = switch (t.usage) {
                    .static => util.Usage.static,
                    .dynamic => util.Usage.dynamic,
                };

                const vbo_pos = try Vbo.init(u16, s.vbo_pos_data[0..(cnt * 8)], usage);
                const vbo_tex = try Vbo.init(u16, s.vbo_tex_data[0..(cnt * 4)], usage);
                const vao = try Vao.init(&.{
                    .{ .size = 2, .vbo = vbo_pos },
                    .{ .size = 1, .vbo = vbo_tex },
                });
                const ebo = try Ebo.init(u16, s.ebo_data[0..(cnt * 6)], usage);

                try data.gui.text.vbo_pos.append(allocator, vbo_pos);
                try data.gui.text.vbo_tex.append(allocator, vbo_tex);
                try data.gui.text.vao.append(allocator, vao);
                try data.gui.text.ebo.append(allocator, ebo);
            } else {
                try data.gui.text.vbo_pos.items[i].subdata(u16, s.vbo_pos_data[0..(cnt * 8)]);
                try data.gui.text.vbo_tex.items[i].subdata(u16, s.vbo_tex_data[0..(cnt * 4)]);
                try data.gui.text.ebo.items[i].subdata(u16, s.ebo_data[0..(cnt * 6)]);
            }
        }

        const pos = t.alignment.transform(t.rect.min * @Vector(2, i32){ gui.scale, gui.scale }, window.size);

        data.gui.text.uniform.vpsize.set(window.size);
        data.gui.text.uniform.scale.set(gui.scale);
        data.gui.text.uniform.pos.set(pos);
        data.gui.text.uniform.color.set(Color{ 1.0, 1.0, 1.0, 1.0 });
        data.gui.text.ebo.items[i].draw(data.gui.text.vao.items[i], .triangles);
    }

    // world
    //world.program.use();
}
