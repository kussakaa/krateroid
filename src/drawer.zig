const std = @import("std");
const zm = @import("zmath");
const gl = @import("zopengl");

const window = @import("window.zig");
const camera = @import("camera.zig");
const world = @import("world.zig");
const gfx = @import("gfx.zig");
const data = @import("data.zig");
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
const _data = struct {
    const world = struct {
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
            };
            var vbo_pos: gfx.Vbo = undefined;
            var vbo_nrm: gfx.Vbo = undefined;
            var vao: gfx.Vao = undefined;
        };
    };
    const gui = struct {
        const button = struct {
            var program: gfx.Program = undefined;
            const uniform = struct {
                var vpsize: gfx.Uniform = undefined;
                var scale: gfx.Uniform = undefined;
                var rect: gfx.Uniform = undefined;
            };
            var vbo: gfx.Vbo = undefined;
            var vao: gfx.Vao = undefined;
            const texture = struct {
                var empty: gfx.Texture = undefined;
                var focus: gfx.Texture = undefined;
                var press: gfx.Texture = undefined;
            };
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
            const texture = struct {
                var font: gfx.Texture = undefined;
            };
        };
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

    { // WORLD
        { // LINE
            _data.world.line.program = try data.program("line");
            _data.world.line.uniform.model = try data.uniform(_data.world.line.program, "model");
            _data.world.line.uniform.view = try data.uniform(_data.world.line.program, "view");
            _data.world.line.uniform.proj = try data.uniform(_data.world.line.program, "proj");
            _data.world.line.uniform.color = try data.uniform(_data.world.line.program, "color");
            _data.world.line.vbo = try gfx.Vbo.init(u8, &.{ 0, 0, 0, 1, 1, 1 }, .static);
            _data.world.line.vao = try gfx.Vao.init(&.{.{ .size = 3, .vbo = _data.world.line.vbo }});
        }
        { // CHUNK
            _data.world.chunk.program = try data.program("chunk");
            _data.world.chunk.uniform.model = try data.uniform(_data.world.chunk.program, "model");
            _data.world.chunk.uniform.view = try data.uniform(_data.world.chunk.program, "view");
            _data.world.chunk.uniform.proj = try data.uniform(_data.world.chunk.program, "proj");
            _data.world.chunk.uniform.color = try data.uniform(_data.world.chunk.program, "color");

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

            _data.world.chunk.vbo_pos = try gfx.Vbo.init(f32, s.vbo_pos_data[0..(cnt * 3)], .static);
            _data.world.chunk.vbo_nrm = try gfx.Vbo.init(f32, s.vbo_nrm_data[0..(cnt * 3)], .static);
            _data.world.chunk.vao = try gfx.Vao.init(&.{
                .{ .size = 3, .vbo = _data.world.chunk.vbo_pos },
                .{ .size = 3, .vbo = _data.world.chunk.vbo_nrm },
            });
        }
    }
    { // GUI
        { // BUTTON
            _data.gui.button.program = try data.program("button");
            _data.gui.button.uniform.vpsize = try data.uniform(_data.gui.button.program, "vpsize");
            _data.gui.button.uniform.scale = try data.uniform(_data.gui.button.program, "scale");
            _data.gui.button.uniform.rect = try data.uniform(_data.gui.button.program, "rect");
            _data.gui.button.vbo = try gfx.Vbo.init(u8, &.{ 0, 0, 0, 1, 1, 0, 1, 1 }, .static);
            _data.gui.button.vao = try gfx.Vao.init(&.{.{ .size = 2, .vbo = _data.gui.button.vbo }});
            _data.gui.button.texture.empty = try data.texture("button/empty.png");
            _data.gui.button.texture.focus = try data.texture("button/focus.png");
            _data.gui.button.texture.press = try data.texture("button/press.png");
        }
        { // TEXT
            _data.gui.text.program = try data.program("text");
            _data.gui.text.uniform.vpsize = try data.uniform(_data.gui.text.program, "vpsize");
            _data.gui.text.uniform.scale = try data.uniform(_data.gui.text.program, "scale");
            _data.gui.text.uniform.pos = try data.uniform(_data.gui.text.program, "pos");
            _data.gui.text.uniform.color = try data.uniform(_data.gui.text.program, "color");
            _data.gui.text.vbo_pos = try Array(gfx.Vbo).initCapacity(_allocator, 32);
            _data.gui.text.vbo_tex = try Array(gfx.Vbo).initCapacity(_allocator, 32);
            _data.gui.text.vao = try Array(gfx.Vao).initCapacity(_allocator, 32);
            _data.gui.text.texture.font = try data.texture("text/font.png");
        }
    }
}

pub fn deinit() void {
    defer _data.world.line.program.deinit();
    defer _data.world.line.vbo.deinit();
    defer _data.world.line.vao.deinit();

    defer _data.world.chunk.program.deinit();
    defer _data.world.chunk.vbo_pos.deinit();
    defer _data.world.chunk.vao.deinit();

    defer _data.gui.button.program.deinit();
    defer _data.gui.button.vbo.deinit();
    defer _data.gui.button.vao.deinit();

    defer _data.gui.text.program.deinit();
    defer _data.gui.text.vbo_pos.deinit(_allocator);
    defer _data.gui.text.vbo_tex.deinit(_allocator);
    defer _data.gui.text.vao.deinit(_allocator);
    defer for (_data.gui.text.vao.items) |item| item.deinit();
    defer for (_data.gui.text.vbo_tex.items) |item| item.deinit();
    defer for (_data.gui.text.vbo_pos.items) |item| item.deinit();
}

pub fn draw() !void {
    // world
    gl.polygonMode(gl.FRONT_AND_BACK, @intFromEnum(polygon_mode));

    // chunk
    gl.enable(gl.DEPTH_TEST);
    _data.world.chunk.program.use();
    _data.world.chunk.uniform.model.set(zm.identity());
    _data.world.chunk.uniform.view.set(camera.view);
    _data.world.chunk.uniform.proj.set(camera.proj);
    _data.world.chunk.uniform.color.set(Color{ 1.0, 1.0, 1.0, 1.0 });
    _data.world.chunk.vao.draw(.triangles);

    gl.disable(gl.DEPTH_TEST);
    // line
    _data.world.line.program.use();
    for (world.lines.items) |l| {
        if (!l.hidden) {
            const model = Mat{
                .{ l.p2[0] - l.p1[0], 0.0, 0.0, 0.0 },
                .{ 0.0, l.p2[1] - l.p1[1], 0.0, 0.0 },
                .{ 0.0, 0.0, l.p2[2] - l.p1[2], 0.0 },
                .{ l.p1[0], l.p1[1], l.p1[2], 1.0 },
            };
            _data.world.chunk.uniform.model.set(model);
            _data.world.chunk.uniform.view.set(camera.view);
            _data.world.chunk.uniform.proj.set(camera.proj);
            _data.world.chunk.uniform.color.set(l.color);
            _data.world.line.vao.draw(.lines);
        }
    }

    // gui

    gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);

    _data.gui.button.program.use();
    for (gui.buttons.items) |b| {
        if (!b.menu.hidden) {
            switch (b.state) {
                .empty => _data.gui.button.texture.empty.use(),
                .focus => _data.gui.button.texture.focus.use(),
                .press => _data.gui.button.texture.press.use(),
            }
            _data.gui.button.uniform.vpsize.set(window.size);
            _data.gui.button.uniform.scale.set(gui.scale);
            _data.gui.button.uniform.rect.set(b.alignment.transform(b.rect.scale(gui.scale), window.size).vector());
            _data.gui.button.vao.draw(.triangle_strip);
        }
    }

    _data.gui.text.program.use();
    _data.gui.text.texture.font.use();
    for (gui.texts.items, 0..) |t, i| {
        if (i == _data.gui.text.vao.items.len or t.usage == .dynamic) {
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

            if (i == _data.gui.text.vao.items.len) {
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

                try _data.gui.text.vbo_pos.append(_allocator, vbo_pos);
                try _data.gui.text.vbo_tex.append(_allocator, vbo_tex);
                try _data.gui.text.vao.append(_allocator, vao);
            } else {
                try _data.gui.text.vbo_pos.items[i].subdata(u16, s.vbo_pos_data[0..(cnt * 12)]);
                try _data.gui.text.vbo_tex.items[i].subdata(u16, s.vbo_tex_data[0..(cnt * 6)]);
            }
        }

        if (!t.menu.hidden) {
            const pos = t.alignment.transform(t.rect.min * @Vector(2, i32){ gui.scale, gui.scale }, window.size);

            _data.gui.text.uniform.vpsize.set(window.size);
            _data.gui.text.uniform.scale.set(gui.scale);
            _data.gui.text.uniform.pos.set(pos);
            _data.gui.text.uniform.color.set(Color{ 1.0, 1.0, 1.0, 1.0 });
            _data.gui.text.vao.items[i].draw(.triangles);
        }
    }
}
