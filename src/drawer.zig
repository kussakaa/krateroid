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

const Mat = zm.Mat;
const Vec = zm.Vec;
const Color = Vec;

var _allocator: Allocator = undefined;
pub var polygon_mode: gl.Enum = gl.FILL;
const light = struct {
    var color: Color = .{ 1.0, 1.0, 1.0, 1.0 };
    var direction: Vec = .{ 1.0, 0.5, 1.0, 1.0 };
    var ambient: f32 = 0.4;
    var diffuse: f32 = 0.3;
    var specular: f32 = 0.1;
};
const _data = struct {
    const line = struct {
        var buffer: *gfx.Buffer = undefined;
        var mesh: *gfx.Mesh = undefined;
        var program: gfx.Program = undefined;
        const uniform = struct {
            var model: gfx.Uniform = undefined;
            var view: gfx.Uniform = undefined;
            var proj: gfx.Uniform = undefined;
            var color: gfx.Uniform = undefined;
        };
    };
    const chunk = struct {
        var buffer_pos: *gfx.Buffer = undefined;
        var buffer_nrm: *gfx.Buffer = undefined;
        var mesh: *gfx.Mesh = undefined;
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
    };
    const rect = struct {
        var buffer: *gfx.Buffer = undefined;
        var mesh: *gfx.Mesh = undefined;
        var program: gfx.Program = undefined;
        const uniform = struct {
            var vpsize: gfx.Uniform = undefined;
            var scale: gfx.Uniform = undefined;
            var rect: gfx.Uniform = undefined;
            var texrect: gfx.Uniform = undefined;
        };
    };
    const panel = struct {
        var texture: *gfx.Texture = undefined;
    };
    const button = struct {
        var texture: *gfx.Texture = undefined;
    };
    const switcher = struct {
        var texture: *gfx.Texture = undefined;
    };
    const slider = struct {
        var texture: *gfx.Texture = undefined;
    };
    const text = struct {
        var program: gfx.Program = undefined;
        const uniform = struct {
            var vpsize: gfx.Uniform = undefined;
            var scale: gfx.Uniform = undefined;
            var pos: gfx.Uniform = undefined;
            var tex: gfx.Uniform = undefined;
            var color: gfx.Uniform = undefined;
        };
        var texture: *gfx.Texture = undefined;
    };
    const cursor = struct {
        var texture: *gfx.Texture = undefined;
    };
};

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
}) !void {
    _allocator = info.allocator;

    gl.enable(gl.MULTISAMPLE);
    gl.enable(gl.LINE_SMOOTH);
    gl.enable(gl.BLEND);
    gl.enable(gl.CULL_FACE);

    gl.lineWidth(2.0);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.cullFace(gl.FRONT);
    gl.frontFace(gl.CW);

    { // LINE
        _data.line.buffer = try gfx.getBuffer("line");
        _data.line.buffer.data(.vertices, &.{ 0, 0, 0, 1, 1, 1 }, .static_draw);
        _data.line.buffer.data_type = .u8;
        _data.line.buffer.vertex_size = 3;
        _data.line.mesh = try gfx.getMesh("line");
        _data.line.mesh.bindBuffer(0, _data.line.buffer);
        _data.line.mesh.mode = .lines;
        _data.line.mesh.count = 2;
        _data.line.program = try gfx.getProgram("line");
        _data.line.uniform.model = try gfx.getUniform(_data.line.program, "model");
        _data.line.uniform.view = try gfx.getUniform(_data.line.program, "view");
        _data.line.uniform.proj = try gfx.getUniform(_data.line.program, "proj");
        _data.line.uniform.color = try gfx.getUniform(_data.line.program, "color");
    }
    { // CHUNK

        const s = struct {
            var buffer_pos_data: [262144]f32 = [1]f32{0.0} ** 262144;
            var buffer_nrm_data: [262144]f32 = [1]f32{0.0} ** 262144;
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

                        s.buffer_pos_data[(cnt + 0) * 3 + 0] = v1[0] + @as(f32, @floatFromInt(x));
                        s.buffer_pos_data[(cnt + 0) * 3 + 1] = v1[1] + @as(f32, @floatFromInt(y));
                        s.buffer_pos_data[(cnt + 0) * 3 + 2] = v1[2] + @as(f32, @floatFromInt(z));
                        s.buffer_pos_data[(cnt + 1) * 3 + 0] = v2[0] + @as(f32, @floatFromInt(x));
                        s.buffer_pos_data[(cnt + 1) * 3 + 1] = v2[1] + @as(f32, @floatFromInt(y));
                        s.buffer_pos_data[(cnt + 1) * 3 + 2] = v2[2] + @as(f32, @floatFromInt(z));
                        s.buffer_pos_data[(cnt + 2) * 3 + 0] = v3[0] + @as(f32, @floatFromInt(x));
                        s.buffer_pos_data[(cnt + 2) * 3 + 1] = v3[1] + @as(f32, @floatFromInt(y));
                        s.buffer_pos_data[(cnt + 2) * 3 + 2] = v3[2] + @as(f32, @floatFromInt(z));

                        const n = zm.cross3(v2 - v1, v3 - v1);

                        s.buffer_nrm_data[(cnt + 0) * 3 + 0] = n[0];
                        s.buffer_nrm_data[(cnt + 0) * 3 + 1] = n[1];
                        s.buffer_nrm_data[(cnt + 0) * 3 + 2] = n[2];
                        s.buffer_nrm_data[(cnt + 1) * 3 + 0] = n[0];
                        s.buffer_nrm_data[(cnt + 1) * 3 + 1] = n[1];
                        s.buffer_nrm_data[(cnt + 1) * 3 + 2] = n[2];
                        s.buffer_nrm_data[(cnt + 2) * 3 + 0] = n[0];
                        s.buffer_nrm_data[(cnt + 2) * 3 + 1] = n[1];
                        s.buffer_nrm_data[(cnt + 2) * 3 + 2] = n[2];

                        cnt += 3;
                    }
                }
            }
        }

        _data.chunk.buffer_pos = try gfx.getBuffer("chunk_pos");
        _data.chunk.buffer_pos.data(.vertices, std.mem.sliceAsBytes(s.buffer_pos_data[0..(cnt * 3)]), .static_draw);
        _data.chunk.buffer_pos.data_type = .f32;
        _data.chunk.buffer_pos.vertex_size = 3;
        _data.chunk.buffer_nrm = try gfx.getBuffer("chunk_nrm");
        _data.chunk.buffer_nrm.data(.vertices, std.mem.sliceAsBytes(s.buffer_nrm_data[0..(cnt * 3)]), .static_draw);
        _data.chunk.buffer_nrm.data_type = .f32;
        _data.chunk.buffer_nrm.vertex_size = 3;

        _data.chunk.mesh = try gfx.getMesh("chunk");
        _data.chunk.mesh.bindBuffer(0, _data.chunk.buffer_pos);
        _data.chunk.mesh.bindBuffer(1, _data.chunk.buffer_nrm);
        _data.chunk.mesh.count = @intCast(cnt);
        _data.chunk.mesh.mode = .triangles;

        _data.chunk.program = try gfx.getProgram("chunk");
        _data.chunk.uniform.model = try gfx.getUniform(_data.chunk.program, "model");
        _data.chunk.uniform.view = try gfx.getUniform(_data.chunk.program, "view");
        _data.chunk.uniform.proj = try gfx.getUniform(_data.chunk.program, "proj");
        _data.chunk.uniform.color = try gfx.getUniform(_data.chunk.program, "color");
        _data.chunk.uniform.light.color = try gfx.getUniform(_data.chunk.program, "light.color");
        _data.chunk.uniform.light.direction = try gfx.getUniform(_data.chunk.program, "light.direction");
        _data.chunk.uniform.light.ambient = try gfx.getUniform(_data.chunk.program, "light.ambient");
        _data.chunk.uniform.light.diffuse = try gfx.getUniform(_data.chunk.program, "light.diffuse");
        _data.chunk.uniform.light.specular = try gfx.getUniform(_data.chunk.program, "light.specular");
    }
    { // RECT
        _data.rect.buffer = try gfx.getBuffer("rect");
        _data.rect.buffer.data(.vertices, &.{ 0, 0, 0, 1, 1, 0, 1, 1 }, .static_draw);
        _data.rect.buffer.data_type = .u8;
        _data.rect.buffer.vertex_size = 2;
        _data.rect.mesh = try gfx.getMesh("rect");
        _data.rect.mesh.bindBuffer(0, _data.rect.buffer);
        _data.rect.mesh.mode = .triangle_strip;
        _data.rect.mesh.count = 4;

        _data.rect.program = try gfx.getProgram("rect");
        _data.rect.uniform.vpsize = try gfx.getUniform(_data.rect.program, "vpsize");
        _data.rect.uniform.scale = try gfx.getUniform(_data.rect.program, "scale");
        _data.rect.uniform.rect = try gfx.getUniform(_data.rect.program, "rect");
        _data.rect.uniform.texrect = try gfx.getUniform(_data.rect.program, "texrect");
    }
    { // PANEL
        _data.panel.texture = try gfx.getTexture("panel.png");
    }
    { // BUTTON
        _data.button.texture = try gfx.getTexture("button.png");
    }
    { // SWITCHER
        _data.switcher.texture = try gfx.getTexture("switcher.png");
    }
    { // SLIDER
        _data.slider.texture = try gfx.getTexture("slider.png");
    }
    { // TEXT
        _data.text.program = try gfx.getProgram("text");
        _data.text.uniform.vpsize = try gfx.getUniform(_data.text.program, "vpsize");
        _data.text.uniform.scale = try gfx.getUniform(_data.text.program, "scale");
        _data.text.uniform.pos = try gfx.getUniform(_data.text.program, "pos");
        _data.text.uniform.tex = try gfx.getUniform(_data.text.program, "tex");
        _data.text.uniform.color = try gfx.getUniform(_data.text.program, "color");
        _data.text.texture = try gfx.getTexture("text.png");
    }
    { // CURSOR
        _data.cursor.texture = try gfx.getTexture("cursor.png");
    }
}

pub fn deinit() void {}

pub fn draw() void {
    gl.enable(gl.DEPTH_TEST);
    gl.polygonMode(gl.FRONT_AND_BACK, polygon_mode);

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
        _data.chunk.mesh.draw();
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
                _data.line.mesh.draw();
            }
        }
    }

    gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);

    { // RECT
        _data.rect.program.use();
        _data.rect.uniform.vpsize.set(window.size);
        _data.rect.uniform.scale.set(gui.scale);
    }
    { // PANEL
        _data.panel.texture.use();
        for (gui.panels.items) |item| {
            if (item.menu.show) {
                _data.rect.uniform.rect.set(
                    item.alignment.transform(item.rect.scale(gui.scale), window.size).vector(),
                );
                _data.rect.uniform.texrect.set(@Vector(4, i32){
                    0,
                    0,
                    @intCast(_data.panel.texture.size[0]),
                    @intCast(_data.panel.texture.size[1]),
                });
                _data.rect.mesh.draw();
            }
        }
    }
    { // BUTTON
        _data.button.texture.use();
        for (gui.buttons.items) |item| {
            if (item.menu.show) {
                _data.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
                switch (item.state) {
                    .empty => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 8, 8 }),
                    .focus => _data.rect.uniform.texrect.set(@Vector(4, i32){ 8, 0, 16, 8 }),
                    .press => _data.rect.uniform.texrect.set(@Vector(4, i32){ 16, 0, 24, 8 }),
                }
                _data.rect.mesh.draw();
            }
        }
    }
    { // SWITCHER
        _data.switcher.texture.use();
        for (gui.switchers.items) |item| {
            if (item.menu.show) {
                _data.rect.uniform.rect.set(
                    item.alignment.transform(gui.Rect{
                        .min = .{
                            item.pos[0] * gui.scale,
                            item.pos[1] * gui.scale,
                        },
                        .max = .{
                            (item.pos[0] + 12) * gui.scale,
                            (item.pos[1] + 8) * gui.scale,
                        },
                    }, window.size).vector(),
                );
                switch (item.state) {
                    .empty => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 6, 8 }),
                    .focus => _data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 0, 12, 8 }),
                    .press => _data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 0, 18, 8 }),
                }
                _data.rect.mesh.draw();

                _data.rect.uniform.rect.set(
                    item.alignment.transform(gui.Rect{
                        .min = .{
                            (item.pos[0] + 2 + @as(i32, @intFromBool(item.status)) * 4) * gui.scale,
                            (item.pos[1]) * gui.scale,
                        },
                        .max = .{
                            (item.pos[0] + 6 + @as(i32, @intFromBool(item.status)) * 4) * gui.scale,
                            (item.pos[1] + 8) * gui.scale,
                        },
                    }, window.size).vector(),
                );
                switch (item.state) {
                    .empty => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 8, 4, 16 }),
                    .focus => _data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 8, 10, 16 }),
                    .press => _data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 8, 16, 16 }),
                }
                _data.rect.mesh.draw();
            }
        }
    }
    { // SLIDER
        _data.slider.texture.use();
        _data.rect.uniform.vpsize.set(window.size);
        _data.rect.uniform.scale.set(gui.scale);
        for (gui.sliders.items) |item| {
            if (item.menu.show) {
                _data.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
                switch (item.state) {
                    .empty => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 6, 8 }),
                    .focus => _data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 0, 12, 8 }),
                    .press => _data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 0, 18, 8 }),
                }
                _data.rect.mesh.draw();

                const len: f32 = @floatFromInt(item.rect.scale(gui.scale).size()[0] - 6 * gui.scale);
                const pos: i32 = @intFromFloat(item.value * len);
                _data.rect.uniform.rect.set(
                    item.alignment.transform(gui.Rect{
                        .min = item.rect.min * gui.Size{ gui.scale, gui.scale } + gui.Pos{ pos, 0 },
                        .max = .{
                            item.rect.min[0] * gui.scale + pos + 6 * gui.scale,
                            item.rect.max[1] * gui.scale,
                        },
                    }, window.size).vector(),
                );
                switch (item.state) {
                    .empty => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 8, 6, 16 }),
                    .focus => _data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 8, 12, 16 }),
                    .press => _data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 8, 18, 16 }),
                }
                _data.rect.mesh.draw();
            }
        }
    }
    { // TEXT
        _data.text.program.use();
        _data.text.texture.use();
        _data.text.uniform.vpsize.set(window.size);
        _data.text.uniform.scale.set(gui.scale);
        _data.text.uniform.color.set(gui.Color{ 1.0, 1.0, 1.0, 1.0 });
        for (gui.texts.items) |item| {
            if (item.menu.show) {
                const pos = item.alignment.transform(item.rect.scale(gui.scale), window.size).min;
                var offset: i32 = 0;
                for (item.data) |cid| {
                    if (cid == ' ') {
                        offset += 3 * gui.scale;
                        continue;
                    }
                    _data.text.uniform.pos.set(gui.Pos{ pos[0] + offset, pos[1] });
                    _data.text.uniform.tex.set(gui.Pos{ gui.font.chars[cid].pos, gui.font.chars[cid].width });
                    _data.rect.mesh.draw();
                    offset += (gui.font.chars[cid].width + 1) * gui.scale;
                }
            }
        }
    }
    { // CURSOR
        _data.rect.program.use();
        _data.cursor.texture.use();
        const p1 = 4 * gui.scale - @divTrunc(gui.scale, 2);
        const p2 = 3 * gui.scale + @divTrunc(gui.scale, 2);
        _data.rect.uniform.rect.set((gui.Rect{
            .min = gui.cursor.pos - gui.Pos{ p1, p1 },
            .max = gui.cursor.pos + gui.Pos{ p2, p2 },
        }).vector());
        switch (gui.cursor.press) {
            false => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 7, 7 }),
            true => _data.rect.uniform.texrect.set(@Vector(4, i32){ 7, 0, 14, 7 }),
        }
        _data.rect.mesh.draw();
    }
}
