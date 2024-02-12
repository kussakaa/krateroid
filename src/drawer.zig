const std = @import("std");
const zm = @import("zmath");
const gl = @import("zopengl").bindings;

// modules
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
var _allocator: Allocator = undefined;
const light = struct {
    var color: Color = .{ 1.0, 1.0, 1.0, 1.0 };
    var direction: Vec = .{ 1.0, 0.5, 1.0, 1.0 };
    var ambient: f32 = 0.4;
    var diffuse: f32 = 0.3;
    var specular: f32 = 0.1;
};
const _data = struct {
    const line = struct {
        var program: gfx.Program = undefined;
        const uniform = struct {
            var model: gfx.Uniform = undefined;
            var view: gfx.Uniform = undefined;
            var proj: gfx.Uniform = undefined;
            var color: gfx.Uniform = undefined;
        };
        var vbo: gfx.Vbo = undefined;
        var vao: gfx.Vao = undefined;
    };
    const chunk = struct {
        var program: gfx.Program = undefined;
        const uniform = struct {
            var model: gfx.Uniform = undefined;
            var view: gfx.Uniform = undefined;
            var proj: gfx.Uniform = undefined;
            var color: gfx.Uniform = undefined;
            const light = struct {
                var color: gfx.Uniform = undefined;
                var direction: gfx.Uniform = undefined;
                var ambient: gfx.Uniform = undefined;
                var diffuse: gfx.Uniform = undefined;
                var specular: gfx.Uniform = undefined;
            };
        };
        var vbo_pos: gfx.Vbo = undefined;
        var vbo_nrm: gfx.Vbo = undefined;
        var vao: gfx.Vao = undefined;
    };
    const rect = struct {
        var program: gfx.Program = undefined;
        const uniform = struct {
            var vpsize: gfx.Uniform = undefined;
            var scale: gfx.Uniform = undefined;
            var rect: gfx.Uniform = undefined;
            var texrect: gfx.Uniform = undefined;
        };
        var vbo: gfx.Vbo = undefined;
        var vao: gfx.Vao = undefined;
    };
    const panel = struct {
        var texture: gfx.Texture = undefined;
    };
    const button = struct {
        var texture: gfx.Texture = undefined;
    };
    const switcher = struct {
        var texture: gfx.Texture = undefined;
    };
    const slider = struct {
        var texture: gfx.Texture = undefined;
    };
    const text = struct {
        var program: gfx.Program = undefined;
        const uniform = struct {
            var vpsize: gfx.Uniform = undefined;
            var scale: gfx.Uniform = undefined;
            var pos: gfx.Uniform = undefined;
            var color: gfx.Uniform = undefined;
        };
        var vbo_pos: Array(gfx.Vbo) = undefined;
        var vbo_tex: Array(gfx.Vbo) = undefined;
        var vao: Array(gfx.Vao) = undefined;
        var texture: gfx.Texture = undefined;
    };
};

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    polygon_mode: gfx.PolygonMode = .fill,
}) !void {
    _allocator = info.allocator;
    polygon_mode = info.polygon_mode;

    gl.enable(gl.MULTISAMPLE);
    gl.enable(gl.LINE_SMOOTH);
    gl.enable(gl.BLEND);
    gl.enable(gl.CULL_FACE);

    gl.lineWidth(2.0);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.cullFace(gl.FRONT);
    gl.frontFace(gl.CW);

    { // LINE
        _data.line.program = try gfx.program("line");
        _data.line.uniform.model = try gfx.uniform(_data.line.program, "model");
        _data.line.uniform.view = try gfx.uniform(_data.line.program, "view");
        _data.line.uniform.proj = try gfx.uniform(_data.line.program, "proj");
        _data.line.uniform.color = try gfx.uniform(_data.line.program, "color");
        _data.line.vbo = try gfx.Vbo.init(u8, &.{ 0, 0, 0, 1, 1, 1 }, .static);
        _data.line.vao = try gfx.Vao.init(&.{.{ .size = 3, .vbo = _data.line.vbo }});
    }
    { // CHUNK
        _data.chunk.program = try gfx.program("chunk");
        _data.chunk.uniform.model = try gfx.uniform(_data.chunk.program, "model");
        _data.chunk.uniform.view = try gfx.uniform(_data.chunk.program, "view");
        _data.chunk.uniform.proj = try gfx.uniform(_data.chunk.program, "proj");
        _data.chunk.uniform.color = try gfx.uniform(_data.chunk.program, "color");
        _data.chunk.uniform.light.color = try gfx.uniform(_data.chunk.program, "light.color");
        _data.chunk.uniform.light.direction = try gfx.uniform(_data.chunk.program, "light.direction");
        _data.chunk.uniform.light.ambient = try gfx.uniform(_data.chunk.program, "light.ambient");
        _data.chunk.uniform.light.diffuse = try gfx.uniform(_data.chunk.program, "light.diffuse");
        _data.chunk.uniform.light.specular = try gfx.uniform(_data.chunk.program, "light.specular");

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
        _data.chunk.vbo_pos = try gfx.Vbo.init(f32, s.vbo_pos_data[0..(cnt * 3)], .static);
        _data.chunk.vbo_nrm = try gfx.Vbo.init(f32, s.vbo_nrm_data[0..(cnt * 3)], .static);
        _data.chunk.vao = try gfx.Vao.init(&.{
            .{ .size = 3, .vbo = _data.chunk.vbo_pos },
            .{ .size = 3, .vbo = _data.chunk.vbo_nrm },
        });
    }
    { // RECT
        _data.rect.vbo = try gfx.Vbo.init(u8, &.{ 0, 0, 0, 1, 1, 0, 1, 1 }, .static);
        _data.rect.vao = try gfx.Vao.init(&.{.{ .size = 2, .vbo = _data.rect.vbo }});
        _data.rect.program = try gfx.program("rect");
        _data.rect.uniform.vpsize = try gfx.uniform(_data.rect.program, "vpsize");
        _data.rect.uniform.scale = try gfx.uniform(_data.rect.program, "scale");
        _data.rect.uniform.rect = try gfx.uniform(_data.rect.program, "rect");
        _data.rect.uniform.texrect = try gfx.uniform(_data.rect.program, "texrect");
    }
    { // PANEL
        _data.panel.texture = try gfx.texture("panel.png");
    }
    { // BUTTON
        _data.button.texture = try gfx.texture("button.png");
    }
    { // SWITCHER
        _data.switcher.texture = try gfx.texture("switcher.png");
    }
    { // SLIDER
        _data.slider.texture = try gfx.texture("slider.png");
    }
    { // TEXT
        _data.text.program = try gfx.program("text");
        _data.text.uniform.vpsize = try gfx.uniform(_data.text.program, "vpsize");
        _data.text.uniform.scale = try gfx.uniform(_data.text.program, "scale");
        _data.text.uniform.pos = try gfx.uniform(_data.text.program, "pos");
        _data.text.uniform.color = try gfx.uniform(_data.text.program, "color");
        _data.text.vbo_pos = try Array(gfx.Vbo).initCapacity(_allocator, 32);
        _data.text.vbo_tex = try Array(gfx.Vbo).initCapacity(_allocator, 32);
        _data.text.vao = try Array(gfx.Vao).initCapacity(_allocator, 32);
        _data.text.texture = try gfx.texture("text.png");
    }
}

pub fn deinit() void {
    defer _data.line.vbo.deinit();
    defer _data.line.vao.deinit();
    defer _data.chunk.vbo_pos.deinit();
    defer _data.chunk.vao.deinit();
    defer _data.rect.vbo.deinit();
    defer _data.rect.vao.deinit();
    defer _data.text.vbo_pos.deinit(_allocator);
    defer _data.text.vbo_tex.deinit(_allocator);
    defer _data.text.vao.deinit(_allocator);
    defer for (_data.text.vao.items) |item| item.deinit();
    defer for (_data.text.vbo_tex.items) |item| item.deinit();
    defer for (_data.text.vbo_pos.items) |item| item.deinit();
}

pub fn draw() !void {
    gl.enable(gl.DEPTH_TEST);
    gl.polygonMode(gl.FRONT_AND_BACK, @intFromEnum(polygon_mode));

    { // CHUNK
        _data.chunk.program.use();
        _data.chunk.uniform.model.set(zm.identity());
        _data.chunk.uniform.view.set(camera.view);
        _data.chunk.uniform.proj.set(camera.proj);
        _data.chunk.uniform.color.set(Color{ 1.0, 1.0, 1.0, 1.0 });
        _data.chunk.uniform.light.color.set(light.color);
        _data.chunk.uniform.light.direction.set(light.direction);
        _data.chunk.uniform.light.ambient.set(light.ambient);
        _data.chunk.uniform.light.diffuse.set(light.diffuse);
        _data.chunk.uniform.light.specular.set(light.specular);
        _data.chunk.vao.draw(.triangles);
    }

    gl.disable(gl.DEPTH_TEST);

    { // LINE
        _data.line.program.use();
        for (world.lines.items) |l| {
            if (l.show) {
                const model = Mat{
                    .{ l.p2[0] - l.p1[0], 0.0, 0.0, 0.0 },
                    .{ 0.0, l.p2[1] - l.p1[1], 0.0, 0.0 },
                    .{ 0.0, 0.0, l.p2[2] - l.p1[2], 0.0 },
                    .{ l.p1[0], l.p1[1], l.p1[2], 1.0 },
                };
                _data.line.uniform.model.set(model);
                _data.line.uniform.view.set(camera.view);
                _data.line.uniform.proj.set(camera.proj);
                _data.line.uniform.color.set(l.color);
                _data.line.vao.draw(.lines);
            }
        }
    }

    //gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);

    { // PANEL
        _data.rect.program.use();
        _data.panel.texture.use();
        for (gui.panels.items) |item| {
            if (item.menu.show) {
                _data.rect.uniform.vpsize.set(window.size);
                _data.rect.uniform.scale.set(gui.scale);
                _data.rect.uniform.rect.set(
                    item.alignment.transform(item.rect.scale(gui.scale), window.size).vector(),
                );
                _data.rect.uniform.texrect.set(
                    gui.rect(0, 0, @intCast(_data.panel.texture.size[0]), @intCast(_data.panel.texture.size[1])).vector(),
                );
                _data.rect.vao.draw(.triangle_strip);
            }
        }
    }
    { // BUTTON
        _data.button.texture.use();
        for (gui.buttons.items) |item| {
            if (item.menu.show) {
                _data.rect.uniform.vpsize.set(window.size);
                _data.rect.uniform.scale.set(gui.scale);
                _data.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
                switch (item.state) {
                    .empty => _data.rect.uniform.texrect.set(gui.rect(0, 0, 8, 8).vector()),
                    .focus => _data.rect.uniform.texrect.set(gui.rect(8, 0, 16, 8).vector()),
                    .press => _data.rect.uniform.texrect.set(gui.rect(16, 0, 24, 8).vector()),
                }
                _data.rect.vao.draw(.triangle_strip);
            }
        }
    }
    { // SWITCHER
        _data.switcher.texture.use();
        for (gui.switchers.items) |item| {
            if (item.menu.show) {
                _data.rect.uniform.vpsize.set(window.size);
                _data.rect.uniform.scale.set(gui.scale);
                _data.rect.uniform.rect.set(
                    item.alignment.transform(gui.rect(
                        item.pos[0] * gui.scale,
                        item.pos[1] * gui.scale,
                        (item.pos[0] + 12) * gui.scale,
                        (item.pos[1] + 8) * gui.scale,
                    ), window.size).vector(),
                );
                switch (item.state) {
                    .empty => _data.rect.uniform.texrect.set(gui.rect(0, 0, 6, 8).vector()),
                    .focus => _data.rect.uniform.texrect.set(gui.rect(6, 0, 12, 8).vector()),
                    .press => _data.rect.uniform.texrect.set(gui.rect(12, 0, 18, 8).vector()),
                }
                _data.rect.vao.draw(.triangle_strip);

                _data.rect.uniform.rect.set(
                    item.alignment.transform(gui.rect(
                        (item.pos[0] + 2 + @as(i32, @intFromBool(item.status)) * 4) * gui.scale,
                        (item.pos[1]) * gui.scale,
                        (item.pos[0] + 6 + @as(i32, @intFromBool(item.status)) * 4) * gui.scale,
                        (item.pos[1] + 8) * gui.scale,
                    ), window.size).vector(),
                );
                switch (item.state) {
                    .empty => _data.rect.uniform.texrect.set(gui.rect(0, 8, 4, 16).vector()),
                    .focus => _data.rect.uniform.texrect.set(gui.rect(6, 8, 10, 16).vector()),
                    .press => _data.rect.uniform.texrect.set(gui.rect(12, 8, 16, 16).vector()),
                }
                _data.rect.vao.draw(.triangle_strip);
            }
        }
    }
    { // SLIDER
        _data.slider.texture.use();
        for (gui.sliders.items) |item| {
            if (item.menu.show) {
                _data.rect.uniform.vpsize.set(window.size);
                _data.rect.uniform.scale.set(gui.scale);
                _data.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
                switch (item.state) {
                    .empty => _data.rect.uniform.texrect.set(gui.rect(0, 0, 6, 8).vector()),
                    .focus => _data.rect.uniform.texrect.set(gui.rect(6, 0, 12, 8).vector()),
                    .press => _data.rect.uniform.texrect.set(gui.rect(12, 0, 18, 8).vector()),
                }
                _data.rect.vao.draw(.triangle_strip);

                const len: f32 = @floatFromInt(item.rect.scale(gui.scale).size()[0] - 6 * gui.scale);
                const pos: i32 = @intFromFloat(item.value * len);
                _data.rect.uniform.rect.set(
                    item.alignment.transform(gui.rect(
                        item.rect.min[0] * gui.scale + pos,
                        item.rect.min[1] * gui.scale,
                        item.rect.min[0] * gui.scale + pos + 6 * gui.scale,
                        item.rect.max[1] * gui.scale,
                    ), window.size).vector(),
                );
                _data.rect.vao.draw(.triangle_strip);
            }
        }
    }
    { // TEXT
        _data.text.program.use();
        _data.text.texture.use();
        for (gui.texts.items, 0..) |t, i| {
            if (i == _data.text.vao.items.len or t.usage == .dynamic) {
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
                    const uvwidth = width;

                    // triangle 1
                    s.vbo_pos_data[cnt * 12 + 0 * 2 + 0] = pos;
                    s.vbo_pos_data[cnt * 12 + 0 * 2 + 1] = 8;
                    s.vbo_pos_data[cnt * 12 + 2 * 2 + 0] = pos + width;
                    s.vbo_pos_data[cnt * 12 + 1 * 2 + 1] = 8;
                    s.vbo_pos_data[cnt * 12 + 1 * 2 + 0] = pos + width;
                    s.vbo_pos_data[cnt * 12 + 2 * 2 + 1] = 0;
                    s.vbo_tex_data[cnt * 6 + 0] = uvpos;
                    s.vbo_tex_data[cnt * 6 + 1] = uvpos + uvwidth;
                    s.vbo_tex_data[cnt * 6 + 2] = uvpos + uvwidth;

                    // triangle 2
                    s.vbo_pos_data[cnt * 12 + 3 * 2 + 0] = pos + width;
                    s.vbo_pos_data[cnt * 12 + 3 * 2 + 1] = 0;
                    s.vbo_pos_data[cnt * 12 + 4 * 2 + 0] = pos;
                    s.vbo_pos_data[cnt * 12 + 4 * 2 + 1] = 0;
                    s.vbo_pos_data[cnt * 12 + 5 * 2 + 0] = pos;
                    s.vbo_pos_data[cnt * 12 + 5 * 2 + 1] = 8;
                    s.vbo_tex_data[cnt * 6 + 3] = uvpos + uvwidth;
                    s.vbo_tex_data[cnt * 6 + 4] = uvpos;
                    s.vbo_tex_data[cnt * 6 + 5] = uvpos;

                    pos += width + 1;
                    cnt += 1;
                }

                if (i == _data.text.vao.items.len) {
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

                    try _data.text.vbo_pos.append(_allocator, vbo_pos);
                    try _data.text.vbo_tex.append(_allocator, vbo_tex);
                    try _data.text.vao.append(_allocator, vao);
                } else {
                    try _data.text.vbo_pos.items[i].subdata(u16, s.vbo_pos_data[0..(cnt * 12)]);
                    try _data.text.vbo_tex.items[i].subdata(u16, s.vbo_tex_data[0..(cnt * 6)]);
                }
            }

            if (t.menu.show) {
                const pos = t.alignment.transform(t.rect.min * @Vector(2, i32){ gui.scale, gui.scale }, window.size);

                _data.text.uniform.vpsize.set(window.size);
                _data.text.uniform.scale.set(gui.scale);
                _data.text.uniform.pos.set(pos);
                _data.text.uniform.color.set(Color{ 1.0, 1.0, 1.0, 1.0 });
                _data.text.vao.items[i].draw(.triangles);
            }
        }
    }
}
