const std = @import("std");
const log = std.log.scoped(.drawer);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;

const c = @import("c.zig");

const window = @import("window.zig");
const gui = @import("gui.zig");
const camera = @import("camera.zig");
const world = @import("world.zig");

// drawer modules
const mct = @import("drawer/mct.zig");

const util = struct {
    usingnamespace @import("gfx/util.zig");
};

// gfx modules
const Vbo = @import("gfx/Vbo.zig");
const Vao = @import("gfx/Vao.zig");
const Ebo = @import("gfx/Ebo.zig");
const Texture = @import("gfx/Texture.zig");
const Shader = @import("gfx/Shader.zig");
const Program = @import("gfx/Program.zig");

// other
const Pos = @Vector(2, i32);
const Size = @Vector(2, i32);

const linmath = @import("linmath.zig");
const Mat = linmath.Mat;
const Vec = linmath.Vec;
const Color = Vec(4);

var allocator: Allocator = undefined;
const data = struct {
    const gui = struct {
        const button = struct {
            var program: Program = undefined;
            const texture = struct {
                var empty: Texture = undefined;
                var focus: Texture = undefined;
                var press: Texture = undefined;
            };
            var vbo: Vbo = undefined;
            var vao: Vao = undefined;
        };
        const text = struct {
            var program: Program = undefined;
            var texture: Texture = undefined;
            var vbo_pos: Array(Vbo) = undefined;
            var vbo_tex: Array(Vbo) = undefined;
            var vao: Array(Vao) = undefined;
        };
    };
    const world = struct {
        const chunk = struct {
            var program: Program = undefined;
            var vbo_pos: Vbo = undefined;
            var vao: Vao = undefined;
        };
    };
};

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
}) !void {
    allocator = info.allocator;

    { // GUI
        { // BUTTON
            const vertex = try Shader.initFormFile("data/gui/button/vertex.glsl", .vertex, allocator);
            const fragment = try Shader.initFormFile("data/gui/button/fragment.glsl", .fragment, allocator);
            defer vertex.deinit();
            defer fragment.deinit();
            data.gui.button.program = try Program.init(
                &.{ vertex, fragment },
                &.{ "vpsize", "scale", "rect" },
                allocator,
            );
            data.gui.button.texture.empty = try Texture.init("data/gui/button/empty.png");
            data.gui.button.texture.focus = try Texture.init("data/gui/button/focus.png");
            data.gui.button.texture.press = try Texture.init("data/gui/button/press.png");
            data.gui.button.vbo = try Vbo.init(u8, &.{ 0, 0, 0, 1, 1, 0, 1, 1 }, .static);
            data.gui.button.vao = try Vao.init(&.{.{ .size = 2, .vbo = data.gui.button.vbo }});
        }
        { // TEXT
            const vertex = try Shader.initFormFile("data/gui/text/vertex.glsl", .vertex, allocator);
            const fragment = try Shader.initFormFile("data/gui/text/fragment.glsl", .fragment, allocator);
            defer vertex.deinit();
            defer fragment.deinit();
            data.gui.text.program = try Program.init(
                &.{ vertex, fragment },
                &.{ "vpsize", "scale", "pos", "color" },
                allocator,
            );
            data.gui.text.texture = try Texture.init("data/gui/text/font.png");
            data.gui.text.vbo_pos = try Array(Vbo).initCapacity(allocator, 32);
            data.gui.text.vbo_tex = try Array(Vbo).initCapacity(allocator, 32);
            data.gui.text.vao = try Array(Vao).initCapacity(allocator, 32);
        }
    }
    { // WORLD
        { // CHUNK
            const vertex = try Shader.initFormFile("data/world/chunk/vertex.glsl", .vertex, allocator);
            const fragment = try Shader.initFormFile("data/world/chunk/fragment.glsl", .fragment, allocator);
            defer vertex.deinit();
            defer fragment.deinit();
            data.world.chunk.program = try Program.init(
                &.{ vertex, fragment },
                &.{ "model", "view", "proj", "color" },
                allocator,
            );
        }
    }
}

pub fn deinit() void {
    data.world.chunk.program.deinit();

    for (data.gui.text.vao.items) |item| item.deinit();
    for (data.gui.text.vbo_tex.items) |item| item.deinit();
    for (data.gui.text.vbo_pos.items) |item| item.deinit();
    data.gui.text.vbo_pos.deinit(allocator);
    data.gui.text.vbo_tex.deinit(allocator);
    data.gui.text.vao.deinit(allocator);
    data.gui.text.program.deinit();

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
        data.gui.button.program.uniforms.items[0].set(window.size);
        data.gui.button.program.uniforms.items[1].set(gui.scale);
        data.gui.button.program.uniforms.items[2].set(b.alignment.transform(b.rect.scale(gui.scale), window.size).vector());
        data.gui.button.vao.draw(.triangle_strip);
    }

    data.gui.text.program.use();
    data.gui.text.texture.use();
    for (gui.texts.items, 0..) |t, i| {
        if (i == data.gui.text.vao.items.len or t.usage == .dynamic) {
            const s = struct {
                var vbo_pos_data: [1024]u16 = [1]u16{0} ** 1024;
                var vbo_tex_data: [512]u16 = [1]u16{0} ** 512;
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

                // triangle 1
                s.vbo_pos_data[cnt * 12 + 0 * 2 + 0] = pos;
                s.vbo_pos_data[cnt * 12 + 0 * 2 + 1] = 0;
                s.vbo_pos_data[cnt * 12 + 1 * 2 + 0] = pos;
                s.vbo_pos_data[cnt * 12 + 1 * 2 + 1] = 8;
                s.vbo_pos_data[cnt * 12 + 2 * 2 + 0] = pos + width;
                s.vbo_pos_data[cnt * 12 + 2 * 2 + 1] = 8;
                s.vbo_tex_data[cnt * 6 + 0] = uvpos;
                s.vbo_tex_data[cnt * 6 + 1] = uvpos;
                s.vbo_tex_data[cnt * 6 + 2] = uvpos + uvwidth;

                // triangle 2
                s.vbo_pos_data[cnt * 12 + 3 * 2 + 0] = pos + width;
                s.vbo_pos_data[cnt * 12 + 3 * 2 + 1] = 8;
                s.vbo_pos_data[cnt * 12 + 4 * 2 + 0] = pos + width;
                s.vbo_pos_data[cnt * 12 + 4 * 2 + 1] = 0;
                s.vbo_pos_data[cnt * 12 + 5 * 2 + 0] = pos;
                s.vbo_pos_data[cnt * 12 + 5 * 2 + 1] = 0;
                s.vbo_tex_data[cnt * 6 + 3] = uvpos + uvwidth;
                s.vbo_tex_data[cnt * 6 + 4] = uvpos + uvwidth;
                s.vbo_tex_data[cnt * 6 + 5] = uvpos;

                pos += width + 1;
                cnt += 1;
            }

            if (i == data.gui.text.vao.items.len) {
                const usage = switch (t.usage) {
                    .static => util.Usage.static,
                    .dynamic => util.Usage.dynamic,
                };

                const vbo_pos = try Vbo.init(u16, s.vbo_pos_data[0..(cnt * 12)], usage);
                const vbo_tex = try Vbo.init(u16, s.vbo_tex_data[0..(cnt * 6)], usage);
                const vao = try Vao.init(&.{
                    .{ .size = 2, .vbo = vbo_pos },
                    .{ .size = 1, .vbo = vbo_tex },
                });

                try data.gui.text.vbo_pos.append(allocator, vbo_pos);
                try data.gui.text.vbo_tex.append(allocator, vbo_tex);
                try data.gui.text.vao.append(allocator, vao);
            } else {
                try data.gui.text.vbo_pos.items[i].subdata(u16, s.vbo_pos_data[0..(cnt * 12)]);
                try data.gui.text.vbo_tex.items[i].subdata(u16, s.vbo_tex_data[0..(cnt * 6)]);
            }
        }

        const pos = t.alignment.transform(t.rect.min * @Vector(2, i32){ gui.scale, gui.scale }, window.size);

        data.gui.text.program.uniforms.items[0].set(window.size);
        data.gui.text.program.uniforms.items[1].set(gui.scale);
        data.gui.text.program.uniforms.items[2].set(pos);
        data.gui.text.program.uniforms.items[3].set(Color{ 1.0, 1.0, 1.0, 1.0 });
        data.gui.text.vao.items[i].draw(.triangles);
    }

    data.world.chunk.program.use();
    data.world.chunk.program.uniforms.items[0].set(linmath.identity(Mat(4)));
    data.world.chunk.program.uniforms.items[1].set(camera.view);
    data.world.chunk.program.uniforms.items[2].set(camera.proj);
    data.world.chunk.program.uniforms.items[2].set(Color{ 0.3, 0.7, 0.3, 1.0 });

    data.world.chunk.vao.draw(.triangles);
}
