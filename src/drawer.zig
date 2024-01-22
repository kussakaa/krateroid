const std = @import("std");
const zm = @import("zmath");
const gl = @import("zopengl");

const window = @import("window.zig");
const camera = @import("camera.zig");
const world = @import("world.zig");
const gfx = @import("gfx.zig");
const gui = @import("gui.zig");
const mct = @import("drawer/mct.zig");

const log = std.log.scoped(.drawer);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;
const Pos = @Vector(2, i32);
const Size = @Vector(2, i32);

const Mat = zm.Mat;
const Vec = zm.Vec;
const Color = Vec;

pub var polygon_mode: gfx.PolygonMode = undefined;
var allocator: Allocator = undefined;
const data = struct {
    const world = struct {
        const line = struct {
            var program: gfx.Program = undefined;
            var vbo: gfx.Vbo = undefined;

            var vao: gfx.Vao = undefined;
        };
        const chunk = struct {
            var program: gfx.Program = undefined;
            var vbo_pos: gfx.Vbo = undefined;
            var vbo_nrm: gfx.Vbo = undefined;
            var vao: gfx.Vao = undefined;
        };
    };
    const gui = struct {
        const button = struct {
            var program: gfx.Program = undefined;
            const texture = struct {
                var empty: gfx.Texture = undefined;
                var focus: gfx.Texture = undefined;
                var press: gfx.Texture = undefined;
            };
            var vbo: gfx.Vbo = undefined;
            var vao: gfx.Vao = undefined;
        };
        const text = struct {
            var program: gfx.Program = undefined;
            var texture: gfx.Texture = undefined;
            var vbo_pos: Array(gfx.Vbo) = undefined;
            var vbo_tex: Array(gfx.Vbo) = undefined;
            var vao: Array(gfx.Vao) = undefined;
        };
    };
};

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    polygon_mode: gfx.PolygonMode = .fill,
}) !void {
    allocator = info.allocator;
    polygon_mode = info.polygon_mode;

    gl.enable(gl.MULTISAMPLE);
    gl.enable(gl.LINE_SMOOTH);
    gl.enable(gl.BLEND);
    gl.enable(gl.CULL_FACE);

    gl.lineWidth(3.0);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.cullFace(gl.FRONT);
    gl.frontFace(gl.CW);

    { // WORLD
        { // LINE
            const vertex = try gfx.Shader.initFormFile("data/world/line/vertex.glsl", .vertex, allocator);
            const fragment = try gfx.Shader.initFormFile("data/world/line/fragment.glsl", .fragment, allocator);
            defer vertex.deinit();
            defer fragment.deinit();
            data.world.line.program = try gfx.Program.init(
                &.{ vertex, fragment },
                &.{ "model", "view", "proj", "color" },
                allocator,
            );
            data.world.line.vbo = try gfx.Vbo.init(u8, &.{ 0, 0, 0, 1, 1, 1 }, .static);
            data.world.line.vao = try gfx.Vao.init(&.{.{ .size = 3, .vbo = data.world.line.vbo }});
        }
        { // CHUNK
            const vertex = try gfx.Shader.initFormFile("data/world/chunk/vertex.glsl", .vertex, allocator);
            const fragment = try gfx.Shader.initFormFile("data/world/chunk/fragment.glsl", .fragment, allocator);
            defer vertex.deinit();
            defer fragment.deinit();
            data.world.chunk.program = try gfx.Program.init(
                &.{ vertex, fragment },
                &.{ "model", "view", "proj", "color" },
                allocator,
            );

            const s = struct {
                var vbo_pos_data: [262144]f32 = [1]f32{0.0} ** 262144;
                var vbo_nrm_data: [262144]f32 = [1]f32{0.0} ** 262144;
            };

            const chunk = world.chunks[0][0].?;
            var cnt: usize = 0;
            for (0..world.Chunk.width - 1) |y| {
                x: for (0..world.Chunk.width - 1) |x| {
                    const minh = @min(chunk.hmap[y][x], chunk.hmap[y][x + 1], chunk.hmap[y + 1][x], chunk.hmap[y + 1][x + 1]);
                    for (minh..255) |z| {
                        var index: u8 = 0;
                        index |= @as(u8, @intFromBool(@as(world.Chunk.H, @intCast(z)) <= chunk.hmap[y][x])) << 3;
                        index |= @as(u8, @intFromBool(@as(world.Chunk.H, @intCast(z)) <= chunk.hmap[y][x + 1])) << 2;
                        index |= @as(u8, @intFromBool(@as(world.Chunk.H, @intCast(z)) <= chunk.hmap[y + 1][x + 1])) << 1;
                        index |= @as(u8, @intFromBool(@as(world.Chunk.H, @intCast(z)) <= chunk.hmap[y + 1][x])) << 0;
                        index |= @as(u8, @intFromBool(@as(world.Chunk.H, @intCast(z + 1)) <= chunk.hmap[y][x])) << 7;
                        index |= @as(u8, @intFromBool(@as(world.Chunk.H, @intCast(z + 1)) <= chunk.hmap[y][x + 1])) << 6;
                        index |= @as(u8, @intFromBool(@as(world.Chunk.H, @intCast(z + 1)) <= chunk.hmap[y + 1][x + 1])) << 5;
                        index |= @as(u8, @intFromBool(@as(world.Chunk.H, @intCast(z + 1)) <= chunk.hmap[y + 1][x])) << 4;

                        if (index == 0) continue :x;

                        var i: usize = 0;
                        while (mct.tri[index][i] < 12) : (i += 3) {
                            const v1 = mct.edge[mct.tri[index][i + 0]];
                            const v2 = mct.edge[mct.tri[index][i + 1]];
                            const v3 = mct.edge[mct.tri[index][i + 2]];

                            s.vbo_pos_data[(cnt + 0) * 3 + 0] = v1[0] + @as(f32, @floatFromInt(x));
                            s.vbo_pos_data[(cnt + 0) * 3 + 1] = v1[1] + @as(f32, @floatFromInt(y));
                            s.vbo_pos_data[(cnt + 0) * 3 + 2] = v1[2] + @as(f32, @floatFromInt(z));
                            s.vbo_pos_data[(cnt + 1) * 3 + 0] = v2[0] + @as(f32, @floatFromInt(x));
                            s.vbo_pos_data[(cnt + 1) * 3 + 1] = v2[1] + @as(f32, @floatFromInt(y));
                            s.vbo_pos_data[(cnt + 1) * 3 + 2] = v2[2] + @as(f32, @floatFromInt(z));
                            s.vbo_pos_data[(cnt + 2) * 3 + 0] = v3[0] + @as(f32, @floatFromInt(x));
                            s.vbo_pos_data[(cnt + 2) * 3 + 1] = v3[1] + @as(f32, @floatFromInt(y));
                            s.vbo_pos_data[(cnt + 2) * 3 + 2] = v3[2] + @as(f32, @floatFromInt(z));

                            const n = zm.cross3(v2 - v1, v3 - v1);

                            s.vbo_nrm_data[(cnt + 0) * 3 + 0] = n[0];
                            s.vbo_nrm_data[(cnt + 0) * 3 + 1] = n[1];
                            s.vbo_nrm_data[(cnt + 0) * 3 + 2] = n[2];
                            s.vbo_nrm_data[(cnt + 1) * 3 + 0] = n[0];
                            s.vbo_nrm_data[(cnt + 1) * 3 + 1] = n[1];
                            s.vbo_nrm_data[(cnt + 1) * 3 + 2] = n[2];
                            s.vbo_nrm_data[(cnt + 2) * 3 + 0] = n[0];
                            s.vbo_nrm_data[(cnt + 2) * 3 + 1] = n[1];
                            s.vbo_nrm_data[(cnt + 2) * 3 + 2] = n[2];

                            cnt += 3;
                        }
                    }
                }
            }

            data.world.chunk.vbo_pos = try gfx.Vbo.init(f32, s.vbo_pos_data[0..(cnt * 3)], .static);
            data.world.chunk.vbo_nrm = try gfx.Vbo.init(f32, s.vbo_nrm_data[0..(cnt * 3)], .static);
            data.world.chunk.vao = try gfx.Vao.init(&.{
                .{ .size = 3, .vbo = data.world.chunk.vbo_pos },
                .{ .size = 3, .vbo = data.world.chunk.vbo_nrm },
            });
        }
    }
    { // GUI
        { // BUTTON
            const vertex = try gfx.Shader.initFormFile("data/gui/button/vertex.glsl", .vertex, allocator);
            const fragment = try gfx.Shader.initFormFile("data/gui/button/fragment.glsl", .fragment, allocator);
            defer vertex.deinit();
            defer fragment.deinit();
            data.gui.button.program = try gfx.Program.init(
                &.{ vertex, fragment },
                &.{ "vpsize", "scale", "rect" },
                allocator,
            );
            data.gui.button.texture.empty = try gfx.Texture.init("data/gui/button/empty.png");
            data.gui.button.texture.focus = try gfx.Texture.init("data/gui/button/focus.png");
            data.gui.button.texture.press = try gfx.Texture.init("data/gui/button/press.png");
            data.gui.button.vbo = try gfx.Vbo.init(u8, &.{ 0, 0, 0, 1, 1, 0, 1, 1 }, .static);
            data.gui.button.vao = try gfx.Vao.init(&.{.{ .size = 2, .vbo = data.gui.button.vbo }});
        }
        { // TEXT
            const vertex = try gfx.Shader.initFormFile("data/gui/text/vertex.glsl", .vertex, allocator);
            const fragment = try gfx.Shader.initFormFile("data/gui/text/fragment.glsl", .fragment, allocator);
            defer vertex.deinit();
            defer fragment.deinit();
            data.gui.text.program = try gfx.Program.init(
                &.{ vertex, fragment },
                &.{ "vpsize", "scale", "pos", "color" },
                allocator,
            );
            data.gui.text.texture = try gfx.Texture.init("data/gui/text/font.png");
            data.gui.text.vbo_pos = try Array(gfx.Vbo).initCapacity(allocator, 32);
            data.gui.text.vbo_tex = try Array(gfx.Vbo).initCapacity(allocator, 32);
            data.gui.text.vao = try Array(gfx.Vao).initCapacity(allocator, 32);
        }
    }
}

pub fn deinit() void {
    defer data.world.line.program.deinit();
    defer data.world.line.vbo.deinit();
    defer data.world.line.vao.deinit();

    defer data.world.chunk.program.deinit();
    defer data.world.chunk.vbo_pos.deinit();
    defer data.world.chunk.vao.deinit();

    defer data.gui.button.program.deinit();
    defer data.gui.button.texture.press.deinit();
    defer data.gui.button.texture.focus.deinit();
    defer data.gui.button.texture.empty.deinit();
    defer data.gui.button.vbo.deinit();
    defer data.gui.button.vao.deinit();

    defer data.gui.text.program.deinit();
    defer data.gui.text.vbo_pos.deinit(allocator);
    defer data.gui.text.vbo_tex.deinit(allocator);
    defer data.gui.text.vao.deinit(allocator);
    defer for (data.gui.text.vao.items) |item| item.deinit();
    defer for (data.gui.text.vbo_tex.items) |item| item.deinit();
    defer for (data.gui.text.vbo_pos.items) |item| item.deinit();
}

pub fn draw() !void {
    // world
    gl.polygonMode(gl.FRONT_AND_BACK, @intFromEnum(polygon_mode));

    // chunk
    gl.enable(gl.DEPTH_TEST);
    data.world.chunk.program.use();
    data.world.chunk.program.uniforms.items[0].set(zm.identity());
    data.world.chunk.program.uniforms.items[1].set(camera.view);
    data.world.chunk.program.uniforms.items[2].set(camera.proj);
    data.world.chunk.program.uniforms.items[3].set(Color{ 1.0, 1.0, 1.0, 1.0 });
    data.world.chunk.vao.draw(.triangles);

    gl.disable(gl.DEPTH_TEST);
    // line
    data.world.line.program.use();
    for (world.lines.items) |l| {
        if (!l.hidden) {
            const model = Mat{
                .{ l.p2[0] - l.p1[0], 0.0, 0.0, 0.0 },
                .{ 0.0, l.p2[1] - l.p1[1], 0.0, 0.0 },
                .{ 0.0, 0.0, l.p2[2] - l.p1[2], 0.0 },
                .{ l.p1[0], l.p1[1], l.p1[2], 1.0 },
            };
            data.world.chunk.program.uniforms.items[0].set(model);
            data.world.chunk.program.uniforms.items[1].set(camera.view);
            data.world.chunk.program.uniforms.items[2].set(camera.proj);
            data.world.chunk.program.uniforms.items[3].set(l.color);
            data.world.line.vao.draw(.lines);
        }
    }

    // gui

    gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);

    data.gui.button.program.use();
    for (gui.buttons.items) |b| {
        if (!b.menu.hidden) {
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
    }

    data.gui.text.program.use();
    data.gui.text.texture.use();
    for (gui.texts.items, 0..) |t, i| {
        if (i == data.gui.text.vao.items.len or t.usage == .dynamic) {
            const s = struct {
                var vbo_pos_data: [4096]u16 = [1]u16{0} ** 4096;
                var vbo_tex_data: [2048]u16 = [1]u16{0} ** 2048;
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
                const usage: gfx.Usage = switch (t.usage) {
                    .static => .static,
                    .dynamic => .dynamic,
                };

                const vbo_pos = try gfx.Vbo.init(u16, s.vbo_pos_data[0..(cnt * 12)], usage);
                const vbo_tex = try gfx.Vbo.init(u16, s.vbo_tex_data[0..(cnt * 6)], usage);
                const vao = try gfx.Vao.init(&.{
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

        if (!t.menu.hidden) {
            const pos = t.alignment.transform(t.rect.min * @Vector(2, i32){ gui.scale, gui.scale }, window.size);

            data.gui.text.program.uniforms.items[0].set(window.size);
            data.gui.text.program.uniforms.items[1].set(gui.scale);
            data.gui.text.program.uniforms.items[2].set(pos);
            data.gui.text.program.uniforms.items[3].set(Color{ 1.0, 1.0, 1.0, 1.0 });
            data.gui.text.vao.items[i].draw(.triangles);
        }
    }
}
