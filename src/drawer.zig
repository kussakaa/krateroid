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
    var direction: Vec = .{ 0.0, 0.0, 1.0, 1.0 };
    var ambient: f32 = 0.4;
    var diffuse: f32 = 0.3;
    var specular: f32 = 0.1;
};

const _data = struct {
    const chunk = struct {
        const width = world.Chunk.width;
        const buffer = struct {
            const pos = struct {
                const vertsize = 3;
                var data = [1]f32{0.0} ** ((width + 1) * (width + 1) * width * vertsize * 3);
                var ptr: *gfx.Buffer = undefined;
            };
            const nrm = struct {
                const vertsize = 3;
                var data = [1]i8{0} ** ((width + 1) * (width + 1) * width * vertsize * 3);
                var ptr: [world.width][world.width]?*gfx.Buffer = undefined;
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
                var ptr: [world.width][world.width]?*gfx.Buffer = undefined;
            };
        };

        var mesh: [world.width][world.width]?*gfx.Mesh = undefined;
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
            const chunk = struct {
                var width: gfx.Uniform = undefined;
                var pos: gfx.Uniform = undefined;
            };
        };
    };
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

        _data.chunk.buffer.pos.ptr = try gfx.buffer(.{
            .name = "chunk_pos",
            .datatype = .f32,
            .vertsize = _data.chunk.buffer.pos.vertsize,
        });
        _data.chunk.buffer.pos.ptr.data(.vbo, std.mem.sliceAsBytes(_data.chunk.buffer.pos.data[0..]), .static_draw);

        for (0..world.width) |y| {
            for (0..world.width) |x| {
                _data.chunk.buffer.nrm.ptr[y][x] = null;
                _data.chunk.buffer.ebo.ptr[y][x] = null;
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
            .datatype = .u8,
            .vertsize = 3,
        });
        _data.line.buffer.data(.vbo, &.{ 0, 0, 0, 1, 1, 1 }, .static_draw);
        _data.line.mesh = try gfx.mesh(.{
            .name = "line",
            .buffers = &.{_data.line.buffer},
            .mode = .lines,
            .len = 2,
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
            .datatype = .u8,
            .vertsize = 2,
        });
        _data.rect.buffer.data(.vbo, &.{ 0, 0, 0, 1, 1, 0, 1, 1 }, .static_draw);
        _data.rect.mesh = try gfx.mesh(.{
            .name = "rect",
            .buffers = &.{_data.rect.buffer},
            .mode = .triangle_strip,
            .len = 4,
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
        _data.chunk.program.use();
        _data.chunk.uniform.model.set(zm.identity());
        _data.chunk.uniform.view.set(camera.view);
        _data.chunk.uniform.proj.set(camera.proj);
        _data.chunk.uniform.color.set(Color{ 0.6, 0.8, 0.6, 1.0 });
        _data.chunk.uniform.light.color.set(light.color);
        _data.chunk.uniform.light.direction.set(light.direction);
        _data.chunk.uniform.light.ambient.set(light.ambient);
        _data.chunk.uniform.light.diffuse.set(light.diffuse);
        _data.chunk.uniform.light.specular.set(light.specular);
        _data.chunk.uniform.chunk.width.set(@as(f32, @floatFromInt(world.Chunk.width)));

        for (0..world.width) |ychunk| {
            for (0..world.width) |xchunk| {
                _data.chunk.uniform.chunk.pos.set(@Vector(3, f32){ @floatFromInt(xchunk), @floatFromInt(ychunk), 0.0 });
                if (_data.chunk.mesh[ychunk][xchunk]) |mesh| {
                    mesh.draw();
                } else if (world.chunks[ychunk][xchunk]) |chunk| {
                    log.debug("init chunk {} {}", .{ xchunk, ychunk });
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

                    _data.chunk.buffer.nrm.ptr[ychunk][xchunk] = try gfx.buffer(.{
                        .name = "chunk_nrm",
                        .datatype = .i8,
                        .vertsize = _data.chunk.buffer.nrm.vertsize,
                    });
                    _data.chunk.buffer.nrm.ptr[ychunk][xchunk].?.data(.vbo, std.mem.sliceAsBytes(_data.chunk.buffer.nrm.data[0..]), .static_draw);
                    _data.chunk.buffer.ebo.ptr[ychunk][xchunk] = try gfx.buffer(.{
                        .name = "chunk_ebo",
                        .datatype = .u32,
                        .vertsize = 1,
                    });
                    _data.chunk.buffer.ebo.ptr[ychunk][xchunk].?.data(.ebo, std.mem.sliceAsBytes(_data.chunk.buffer.ebo.data[0..len]), .static_draw);

                    _data.chunk.mesh[ychunk][xchunk] = try gfx.mesh(.{
                        .name = "chunk",
                        .buffers = &.{
                            _data.chunk.buffer.pos.ptr,
                            _data.chunk.buffer.nrm.ptr[ychunk][xchunk].?,
                        },
                        .len = @intCast(len),
                        .mode = .triangles,
                        .ebo = _data.chunk.buffer.ebo.ptr[ychunk][xchunk].?,
                    });
                    _data.chunk.mesh[ychunk][xchunk].?.draw();
                }
            }
        }
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
