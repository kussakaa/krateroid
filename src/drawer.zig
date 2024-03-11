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
pub const colors = struct {
    pub var bg: Color = .{ 0.0, 0.0, 0.0, 1.0 };
};
const light = struct {
    var color: Color = .{ 1.0, 1.0, 1.0, 1.0 };
    var direction: Vec = .{ 1.0, 0.0, 1.0, 1.0 };
    var ambient: f32 = 0.4;
    var diffuse: f32 = 0.4;
    var specular: f32 = 0.1;
};

const _data = struct {
    const chunk = struct {
        const width = world.Chunk.width;
        const buffer = struct {
            const pos = struct {
                const vertsize = 3;
                var data = [1]f32{0.0} ** ((width + 1) * (width + 1) * width * vertsize * 3);
                var id: gfx.Buffer.Id = undefined;
            };
            const nrm = struct {
                const vertsize = 3;
                var data = [1]i8{0} ** ((width + 1) * (width + 1) * width * vertsize * 3);
                var id: [world.width][world.width]?gfx.Buffer.Id = undefined;
            };
            const ebo = struct {
                const xoffset = (width + 1) * (width + 1) * width * 0;
                const yoffset = (width + 1) * (width + 1) * width * 1;
                const zoffset = (width + 1) * (width + 1) * width * 2;
                const edge = [12]u32{
                    xoffset + width,
                    yoffset + 1,
                    xoffset,
                    yoffset,

                    xoffset + (width + 1) * width + width,
                    yoffset + (width + 1) * width + 1,
                    xoffset + (width + 1) * width,
                    yoffset + (width + 1) * width,

                    zoffset + width,
                    zoffset + width + 1,
                    zoffset + 1,
                    zoffset,
                };
                var data = [1]u32{0} ** (1024 * 1024); // 1 Mb
                var id: [world.width][world.width]?gfx.Buffer.Id = undefined;
            };
        };

        var mesh: [world.width][world.width]?gfx.Mesh.Id = undefined;
        var program: gfx.Program.Id = undefined;
        const uniform = struct {
            var model: gfx.Uniform.Id = undefined;
            var view: gfx.Uniform.Id = undefined;
            var proj: gfx.Uniform.Id = undefined;
            var color: gfx.Uniform.Id = undefined;
            const light = struct {
                var color: gfx.Uniform.Id = undefined;
                var direction: gfx.Uniform.Id = undefined;
                var ambient: gfx.Uniform.Id = undefined;
                var diffuse: gfx.Uniform.Id = undefined;
                var specular: gfx.Uniform.Id = undefined;
            };
            const chunk = struct {
                var width: gfx.Uniform.Id = undefined;
                var pos: gfx.Uniform.Id = undefined;
            };
        };
    };
    const line = struct {
        var buffer: gfx.Buffer.Id = undefined;
        var mesh: gfx.Mesh.Id = undefined;
        var program: gfx.Program.Id = undefined;
        const uniform = struct {
            var model: gfx.Uniform.Id = undefined;
            var view: gfx.Uniform.Id = undefined;
            var proj: gfx.Uniform.Id = undefined;
            var color: gfx.Uniform.Id = undefined;
        };
    };
    const rect = struct {
        var buffer: gfx.Buffer.Id = undefined;
        var mesh: gfx.Mesh.Id = undefined;
        var program: gfx.Program.Id = undefined;
        const uniform = struct {
            var vpsize: gfx.Uniform.Id = undefined;
            var scale: gfx.Uniform.Id = undefined;
            var rect: gfx.Uniform.Id = undefined;
            var texrect: gfx.Uniform.Id = undefined;
        };
    };
    const panel = struct {
        var texture: gfx.Texture.Id = undefined;
    };
    const button = struct {
        var texture: gfx.Texture.Id = undefined;
    };
    const switcher = struct {
        var texture: gfx.Texture.Id = undefined;
    };
    const slider = struct {
        var texture: gfx.Texture.Id = undefined;
    };
    const text = struct {
        var program: gfx.Program.Id = undefined;
        const uniform = struct {
            var vpsize: gfx.Uniform.Id = undefined;
            var scale: gfx.Uniform.Id = undefined;
            var pos: gfx.Uniform.Id = undefined;
            var tex: gfx.Uniform.Id = undefined;
            var color: gfx.Uniform.Id = undefined;
        };
        var texture: gfx.Texture.Id = undefined;
    };
    const cursor = struct {
        var texture: gfx.Texture.Id = undefined;
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

    gl.lineWidth(1.0);
    gl.pointSize(1.0);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.cullFace(gl.FRONT);
    gl.frontFace(gl.CW);

    { // CHUNK

        const width = world.Chunk.width;

        // x space
        for (0..(width + 1)) |z| {
            for (0..(width + 1)) |y| {
                for (0..(width)) |x| {
                    const offset = (x + y * (width) + z * (width * (width + 1)));
                    _data.chunk.buffer.pos.data[(_data.chunk.buffer.ebo.xoffset + offset) * _data.chunk.buffer.pos.vertsize + 0] = @as(f32, @floatFromInt(x)) + 0.5;
                    _data.chunk.buffer.pos.data[(_data.chunk.buffer.ebo.xoffset + offset) * _data.chunk.buffer.pos.vertsize + 1] = @as(f32, @floatFromInt(y));
                    _data.chunk.buffer.pos.data[(_data.chunk.buffer.ebo.xoffset + offset) * _data.chunk.buffer.pos.vertsize + 2] = @as(f32, @floatFromInt(z));
                }
            }
        }

        // y space
        for (0..(width + 1)) |z| {
            for (0..(width)) |y| {
                for (0..(width + 1)) |x| {
                    const offset = (x + y * (width) + z * (width * (width + 1)));
                    _data.chunk.buffer.pos.data[(_data.chunk.buffer.ebo.yoffset + offset) * _data.chunk.buffer.pos.vertsize + 0] = @as(f32, @floatFromInt(x));
                    _data.chunk.buffer.pos.data[(_data.chunk.buffer.ebo.yoffset + offset) * _data.chunk.buffer.pos.vertsize + 1] = @as(f32, @floatFromInt(y)) + 0.5;
                    _data.chunk.buffer.pos.data[(_data.chunk.buffer.ebo.yoffset + offset) * _data.chunk.buffer.pos.vertsize + 2] = @as(f32, @floatFromInt(z));
                }
            }
        }

        // z space
        for (0..(width)) |z| {
            for (0..(width + 1)) |y| {
                for (0..(width + 1)) |x| {
                    const offset = (x + y * (width) + z * (width * (width + 1)));
                    _data.chunk.buffer.pos.data[(_data.chunk.buffer.ebo.zoffset + offset) * _data.chunk.buffer.pos.vertsize + 0] = @as(f32, @floatFromInt(x));
                    _data.chunk.buffer.pos.data[(_data.chunk.buffer.ebo.zoffset + offset) * _data.chunk.buffer.pos.vertsize + 1] = @as(f32, @floatFromInt(y));
                    _data.chunk.buffer.pos.data[(_data.chunk.buffer.ebo.zoffset + offset) * _data.chunk.buffer.pos.vertsize + 2] = @as(f32, @floatFromInt(z)) + 0.5;
                }
            }
        }

        _data.chunk.buffer.pos.id = try gfx.buffer(.{
            .name = "chunk_pos",
            .target = .vbo,
            .datatype = .f32,
            .vertsize = _data.chunk.buffer.pos.vertsize,
            .usage = .static_draw,
        });
        gfx.bufferData(_data.chunk.buffer.pos.id, std.mem.sliceAsBytes(_data.chunk.buffer.pos.data[0..]));

        for (0..world.width) |y| {
            for (0..world.width) |x| {
                _data.chunk.buffer.nrm.id[y][x] = null;
                _data.chunk.buffer.ebo.id[y][x] = null;
                _data.chunk.mesh[y][x] = null;
            }
        }

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
        _data.chunk.uniform.chunk.width = try gfx.uniform(_data.chunk.program, "chunk.width");
        _data.chunk.uniform.chunk.pos = try gfx.uniform(_data.chunk.program, "chunk.pos");
    }
    { // LINE
        _data.line.buffer = try gfx.buffer(.{
            .name = "line",
            .target = .vbo,
            .datatype = .u8,
            .vertsize = 3,
            .usage = .static_draw,
        });
        gfx.bufferData(_data.line.buffer, &.{ 0, 0, 0, 1, 1, 1 });
        _data.line.mesh = try gfx.mesh(.{
            .name = "line",
            .buffers = &.{_data.line.buffer},
            .vertcnt = 2,
            .drawmode = .lines,
        });
        _data.line.program = try gfx.program("line");
        _data.line.uniform.model = try gfx.uniform(_data.line.program, "model");
        _data.line.uniform.view = try gfx.uniform(_data.line.program, "view");
        _data.line.uniform.proj = try gfx.uniform(_data.line.program, "proj");
        _data.line.uniform.color = try gfx.uniform(_data.line.program, "color");
    }
    { // RECT
        _data.rect.buffer = try gfx.buffer(.{
            .name = "rect",
            .target = .vbo,
            .datatype = .u8,
            .vertsize = 2,
            .usage = .static_draw,
        });
        gfx.bufferData(_data.rect.buffer, &.{ 0, 0, 0, 1, 1, 0, 1, 1 });
        _data.rect.mesh = try gfx.mesh(.{
            .name = "rect",
            .buffers = &.{_data.rect.buffer},
            .vertcnt = 4,
            .drawmode = .triangle_strip,
        });
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
        _data.text.uniform.tex = try gfx.uniform(_data.text.program, "tex");
        _data.text.uniform.color = try gfx.uniform(_data.text.program, "color");
        _data.text.texture = try gfx.texture("text.png");
    }
    { // CURSOR
        _data.cursor.texture = try gfx.texture("cursor.png");
    }
}

pub fn deinit() void {}

pub fn draw() !void {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.clearColor(colors.bg[0], colors.bg[1], colors.bg[2], colors.bg[3]);
    gl.enable(gl.DEPTH_TEST);
    gl.polygonMode(gl.FRONT_AND_BACK, polygon_mode);

    { // CHUNK
        gfx.programUse(_data.chunk.program);
        gfx.uniformSet(_data.chunk.uniform.model, zm.identity());
        gfx.uniformSet(_data.chunk.uniform.view, camera.view);
        gfx.uniformSet(_data.chunk.uniform.proj, camera.proj);
        gfx.uniformSet(_data.chunk.uniform.color, Color{ 0.6, 0.8, 0.6, 1.0 });
        gfx.uniformSet(_data.chunk.uniform.light.color, light.color);
        gfx.uniformSet(_data.chunk.uniform.light.direction, light.direction);
        gfx.uniformSet(_data.chunk.uniform.light.ambient, light.ambient);
        gfx.uniformSet(_data.chunk.uniform.light.diffuse, light.diffuse);
        gfx.uniformSet(_data.chunk.uniform.light.specular, light.specular);
        gfx.uniformSet(_data.chunk.uniform.chunk.width, @as(f32, @floatFromInt(world.Chunk.width)));

        for (0..world.width) |ychunk| {
            for (0..world.width) |xchunk| {
                gfx.uniformSet(_data.chunk.uniform.chunk.pos, @Vector(3, f32){ @floatFromInt(xchunk), @floatFromInt(ychunk), 0.0 });
                if (_data.chunk.mesh[ychunk][xchunk]) |mesh| {
                    gfx.meshDraw(mesh);
                } else if (world.chunks[ychunk][xchunk]) |chunk| {
                    const width = world.Chunk.width;
                    @memset(_data.chunk.buffer.nrm.data[0..], 0);
                    var len: usize = 0;
                    for (0..width - 1) |z| {
                        for (0..width - 1) |y| {
                            for (0..width - 1) |x| {
                                var index: u8 = 0;
                                index |= @as(u8, @intFromBool(chunk.grid[z][y][x])) << 3;
                                index |= @as(u8, @intFromBool(chunk.grid[z][y][x + 1])) << 2;
                                index |= @as(u8, @intFromBool(chunk.grid[z][y + 1][x + 1])) << 1;
                                index |= @as(u8, @intFromBool(chunk.grid[z][y + 1][x])) << 0;
                                index |= @as(u8, @intFromBool(chunk.grid[z + 1][y][x])) << 7;
                                index |= @as(u8, @intFromBool(chunk.grid[z + 1][y][x + 1])) << 6;
                                index |= @as(u8, @intFromBool(chunk.grid[z + 1][y + 1][x + 1])) << 5;
                                index |= @as(u8, @intFromBool(chunk.grid[z + 1][y + 1][x])) << 4;
                                if (index == 0) continue;
                                var i: usize = 0;
                                while (mct.pos[index][i] < 12) : (i += 3) {
                                    const v1: u32 = _data.chunk.buffer.ebo.edge[mct.pos[index][i + 0]] + @as(u32, @intCast(x + y * width + z * width * (width + 1)));
                                    const v2: u32 = _data.chunk.buffer.ebo.edge[mct.pos[index][i + 1]] + @as(u32, @intCast(x + y * width + z * width * (width + 1)));
                                    const v3: u32 = _data.chunk.buffer.ebo.edge[mct.pos[index][i + 2]] + @as(u32, @intCast(x + y * width + z * width * (width + 1)));

                                    _data.chunk.buffer.ebo.data[len + 0] = v1;
                                    _data.chunk.buffer.ebo.data[len + 1] = v2;
                                    _data.chunk.buffer.ebo.data[len + 2] = v3;

                                    const n = @Vector(3, i8){
                                        mct.nrm[index][i + 0],
                                        mct.nrm[index][i + 1],
                                        mct.nrm[index][i + 2],
                                    };

                                    _data.chunk.buffer.nrm.data[v1 * _data.chunk.buffer.nrm.vertsize + 0] += n[0];
                                    _data.chunk.buffer.nrm.data[v1 * _data.chunk.buffer.nrm.vertsize + 1] += n[1];
                                    _data.chunk.buffer.nrm.data[v1 * _data.chunk.buffer.nrm.vertsize + 2] += n[2];
                                    _data.chunk.buffer.nrm.data[v2 * _data.chunk.buffer.nrm.vertsize + 0] += n[0];
                                    _data.chunk.buffer.nrm.data[v2 * _data.chunk.buffer.nrm.vertsize + 1] += n[1];
                                    _data.chunk.buffer.nrm.data[v2 * _data.chunk.buffer.nrm.vertsize + 2] += n[2];
                                    _data.chunk.buffer.nrm.data[v3 * _data.chunk.buffer.nrm.vertsize + 0] += n[0];
                                    _data.chunk.buffer.nrm.data[v3 * _data.chunk.buffer.nrm.vertsize + 1] += n[1];
                                    _data.chunk.buffer.nrm.data[v3 * _data.chunk.buffer.nrm.vertsize + 2] += n[2];
                                    len += 3;
                                }
                            }
                        }
                    }

                    _data.chunk.buffer.nrm.id[ychunk][xchunk] = try gfx.buffer(.{
                        .name = "chunk_nrm",
                        .target = .vbo,
                        .datatype = .i8,
                        .vertsize = _data.chunk.buffer.nrm.vertsize,
                        .usage = .static_draw,
                    });
                    gfx.bufferData(_data.chunk.buffer.nrm.id[ychunk][xchunk].?, std.mem.sliceAsBytes(_data.chunk.buffer.nrm.data[0..]));
                    _data.chunk.buffer.ebo.id[ychunk][xchunk] = try gfx.buffer(.{
                        .name = "chunk_ebo",
                        .target = .ebo,
                        .datatype = .u32,
                        .vertsize = 1,
                        .usage = .static_draw,
                    });
                    gfx.bufferData(_data.chunk.buffer.ebo.id[ychunk][xchunk].?, std.mem.sliceAsBytes(_data.chunk.buffer.ebo.data[0..len]));

                    _data.chunk.mesh[ychunk][xchunk] = try gfx.mesh(.{
                        .name = "chunk",
                        .buffers = &.{
                            _data.chunk.buffer.pos.id,
                            _data.chunk.buffer.nrm.id[ychunk][xchunk].?,
                        },
                        .vertcnt = @intCast(len),
                        .drawmode = .triangles,
                        .ebo = _data.chunk.buffer.ebo.id[ychunk][xchunk].?,
                    });
                    gfx.meshDraw(_data.chunk.mesh[ychunk][xchunk].?);
                }
            }
        }
    }

    gl.disable(gl.DEPTH_TEST);

    { // LINE
        gfx.programUse(_data.line.program);
        for (world.lines.items) |l| {
            if (l.show) {
                const model = Mat{
                    .{ l.p2[0] - l.p1[0], 0.0, 0.0, 0.0 },
                    .{ 0.0, l.p2[1] - l.p1[1], 0.0, 0.0 },
                    .{ 0.0, 0.0, l.p2[2] - l.p1[2], 0.0 },
                    .{ l.p1[0], l.p1[1], l.p1[2], 1.0 },
                };
                gfx.uniformSet(_data.line.uniform.model, model);
                gfx.uniformSet(_data.line.uniform.view, camera.view);
                gfx.uniformSet(_data.line.uniform.proj, camera.proj);
                gfx.uniformSet(_data.line.uniform.color, l.color);
                gfx.meshDraw(_data.line.mesh);
            }
        }
    }

    gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);

    { // RECT
        gfx.programUse(_data.rect.program);
        gfx.uniformSet(_data.rect.uniform.vpsize, window.size);
        gfx.uniformSet(_data.rect.uniform.scale, gui.scale);
    }
    { // PANEL
        gfx.textureUse(_data.panel.texture);
        for (gui.panels.items) |item| {
            if (gui.menus.items[item.menu].show) {
                gfx.uniformSet(
                    _data.rect.uniform.rect,
                    item.alignment.transform(item.rect.scale(gui.scale), window.size).vector(),
                );
                gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){
                    0,
                    0,
                    @intCast(gfx.textures.items[_data.panel.texture].size[0]),
                    @intCast(gfx.textures.items[_data.panel.texture].size[1]),
                });
                gfx.meshDraw(_data.rect.mesh);
            }
        }
    }
    { // BUTTON
        gfx.textureUse(_data.button.texture);
        for (gui.buttons.items) |item| {
            if (gui.menus.items[item.menu].show) {
                gfx.uniformSet(_data.rect.uniform.rect, item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
                switch (item.state) {
                    .empty => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 0, 0, 8, 8 }),
                    .focus => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 8, 0, 16, 8 }),
                    .press => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 16, 0, 24, 8 }),
                }
                gfx.meshDraw(_data.rect.mesh);
            }
        }
    }
    { // SWITCHER
        gfx.textureUse(_data.switcher.texture);
        for (gui.switchers.items) |item| {
            if (gui.menus.items[item.menu].show) {
                gfx.uniformSet(
                    _data.rect.uniform.rect,
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
                    .empty => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 0, 0, 6, 8 }),
                    .focus => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 6, 0, 12, 8 }),
                    .press => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 12, 0, 18, 8 }),
                }
                gfx.meshDraw(_data.rect.mesh);

                gfx.uniformSet(
                    _data.rect.uniform.rect,
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
                    .empty => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 0, 8, 4, 16 }),
                    .focus => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 6, 8, 10, 16 }),
                    .press => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 12, 8, 16, 16 }),
                }
                gfx.meshDraw(_data.rect.mesh);
            }
        }
    }
    { // SLIDER
        gfx.textureUse(_data.slider.texture);
        gfx.uniformSet(_data.rect.uniform.vpsize, window.size);
        gfx.uniformSet(_data.rect.uniform.scale, gui.scale);
        for (gui.sliders.items) |item| {
            if (gui.menus.items[item.menu].show) {
                gfx.uniformSet(_data.rect.uniform.rect, item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
                switch (item.state) {
                    .empty => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 0, 0, 6, 8 }),
                    .focus => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 6, 0, 12, 8 }),
                    .press => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 12, 0, 18, 8 }),
                }
                gfx.meshDraw(_data.rect.mesh);

                const len: f32 = @floatFromInt(item.rect.scale(gui.scale).size()[0] - 6 * gui.scale);
                const pos: i32 = @intFromFloat(item.value * len);
                gfx.uniformSet(
                    _data.rect.uniform.rect,
                    item.alignment.transform(gui.Rect{
                        .min = item.rect.min * gui.Size{ gui.scale, gui.scale } + gui.Pos{ pos, 0 },
                        .max = .{
                            item.rect.min[0] * gui.scale + pos + 6 * gui.scale,
                            item.rect.max[1] * gui.scale,
                        },
                    }, window.size).vector(),
                );
                switch (item.state) {
                    .empty => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 0, 8, 6, 16 }),
                    .focus => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 6, 8, 12, 16 }),
                    .press => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 12, 8, 18, 16 }),
                }
                gfx.meshDraw(_data.rect.mesh);
            }
        }
    }
    { // TEXT
        gfx.programUse(_data.text.program);
        gfx.textureUse(_data.text.texture);
        gfx.uniformSet(_data.text.uniform.vpsize, window.size);
        gfx.uniformSet(_data.text.uniform.scale, gui.scale);
        gfx.uniformSet(_data.text.uniform.color, gui.Color{ 1.0, 1.0, 1.0, 1.0 });
        for (gui.texts.items) |item| {
            if (gui.menus.items[item.menu].show) {
                const pos = item.alignment.transform(item.rect.scale(gui.scale), window.size).min;
                var offset: i32 = 0;
                for (item.data) |cid| {
                    if (cid == ' ') {
                        offset += 3 * gui.scale;
                        continue;
                    }
                    gfx.uniformSet(_data.text.uniform.pos, gui.Pos{ pos[0] + offset, pos[1] });
                    gfx.uniformSet(_data.text.uniform.tex, gui.Pos{ gui.font.chars[cid].pos, gui.font.chars[cid].width });
                    gfx.meshDraw(_data.rect.mesh);
                    offset += (gui.font.chars[cid].width + 1) * gui.scale;
                }
            }
        }
    }
    { // CURSOR
        gfx.programUse(_data.rect.program);
        gfx.textureUse(_data.cursor.texture);
        const p1 = 4 * gui.scale - @divTrunc(gui.scale, 2);
        const p2 = 3 * gui.scale + @divTrunc(gui.scale, 2);
        gfx.uniformSet(_data.rect.uniform.rect, (gui.Rect{
            .min = gui.cursor.pos - gui.Pos{ p1, p1 },
            .max = gui.cursor.pos + gui.Pos{ p2, p2 },
        }).vector());
        switch (gui.cursor.press) {
            false => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 0, 0, 7, 7 }),
            true => gfx.uniformSet(_data.rect.uniform.texrect, @Vector(4, i32){ 7, 0, 14, 7 }),
        }
        gfx.meshDraw(_data.rect.mesh);
    }
}
