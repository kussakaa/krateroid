const std = @import("std");
const log = std.log.scoped(.drawer);
const zm = @import("zmath");
const gl = @import("zopengl").bindings;

const config = @import("config.zig");
const window = @import("window.zig");
const camera = @import("camera.zig");
const world = @import("world.zig");
const shape = @import("shape.zig");
const gfx = @import("gfx.zig");
const gui = @import("gui.zig");

const Allocator = std.mem.Allocator;
const Mat = zm.Mat;
const Vec = zm.Vec;

const _data = @import("drawer/data.zig");
const _mct = @import("drawer/mct.zig");
var _allocator: Allocator = undefined;

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
}) !void {
    _allocator = info.allocator;

    gl.enable(gl.MULTISAMPLE);
    gl.enable(gl.LINE_SMOOTH);
    gl.enable(gl.BLEND);
    gl.enable(gl.CULL_FACE);

    gl.lineWidth(2.0);
    gl.pointSize(3.0);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.cullFace(gl.FRONT);
    gl.frontFace(gl.CW);

    try _data.init(_allocator);
}

pub fn deinit() void {
    _data.deinit();
}

pub fn draw() !void {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.clearColor(config.drawer.background.color[0], config.drawer.background.color[1], config.drawer.background.color[2], config.drawer.background.color[3]);

    gl.enable(gl.DEPTH_TEST);
    gl.polygonMode(gl.FRONT_AND_BACK, if (config.debug.show_grid) gl.LINE else gl.FILL);
    try drawWorld();

    gl.disable(gl.DEPTH_TEST);
    drawShape();

    gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);
    drawGui();
}

fn drawWorld() !void {
    try drawWorldChunk();
    drawWorldProjectile();
}

fn drawWorldChunk() !void {
    const terra_w = world.getTerraW();
    const terra_h = world.getTerraH();
    const chunk_w = world.getChunkW();

    const vertex_size = 3;
    const normal_size = 3;
    const s = struct {
        var vertex_buffer_data = [1]f32{0.0} ** (1024 * 1024 * vertex_size);
        var normal_buffer_data = [1]i8{0} ** (1024 * 1024 * normal_size);
    };

    _data.world.chunk.program.use();
    _data.world.chunk.texture.dirt.use();
    _data.world.chunk.uniform.model.set(zm.identity());
    _data.world.chunk.uniform.view.set(camera.view);
    _data.world.chunk.uniform.proj.set(camera.proj);
    _data.world.chunk.uniform.light.color.set(config.drawer.light.color);
    _data.world.chunk.uniform.light.direction.set(config.drawer.light.direction);
    _data.world.chunk.uniform.light.ambient.set(config.drawer.light.ambient);
    _data.world.chunk.uniform.light.diffuse.set(config.drawer.light.diffuse);
    _data.world.chunk.uniform.light.specular.set(config.drawer.light.specular);
    _data.world.chunk.uniform.chunk.width.set(@as(f32, @floatFromInt(chunk_w)));

    var chunk_pos = world.ChunkPos{ 0, 0, 0 };
    while (chunk_pos[2] < terra_h) : (chunk_pos[2] += 1) {
        chunk_pos[1] = 0;
        while (chunk_pos[1] < terra_w) : (chunk_pos[1] += 1) {
            chunk_pos[0] = 0;
            while (chunk_pos[0] < terra_w) : (chunk_pos[0] += 1) {
                _data.world.chunk.uniform.chunk.pos.set(@Vector(3, f32){ @floatFromInt(chunk_pos[0]), @floatFromInt(chunk_pos[1]), @floatFromInt(chunk_pos[2]) });
                if (_data.world.chunk.meshes[world.chunkIdFromChunkPos(chunk_pos)]) |mesh| {
                    mesh.draw();
                } else if (world.isInitChunk(world.chunkIdFromChunkPos(chunk_pos))) {
                    var len: usize = 0;
                    var block_pos = world.BlockPos{ 0, 0, 0 };
                    while (block_pos[2] < chunk_w) : (block_pos[2] += 1) {
                        block_pos[1] = 0;
                        while (block_pos[1] < chunk_w) : (block_pos[1] += 1) {
                            block_pos[0] = 0;
                            while (block_pos[0] < chunk_w) : (block_pos[0] += 1) {
                                var id: u8 = 0;

                                const isInitChunk100 = world.isInitChunkFromPos(chunk_pos + world.ChunkPos{ 1, 0, 0 });
                                const isInitChunk010 = world.isInitChunkFromPos(chunk_pos + world.ChunkPos{ 0, 1, 0 });
                                const isInitChunk001 = world.isInitChunkFromPos(chunk_pos + world.ChunkPos{ 0, 0, 1 });
                                const isInitChunk110 = world.isInitChunkFromPos(chunk_pos + world.ChunkPos{ 1, 1, 0 });
                                const isInitChunk011 = world.isInitChunkFromPos(chunk_pos + world.ChunkPos{ 0, 1, 1 });
                                const isInitChunk101 = world.isInitChunkFromPos(chunk_pos + world.ChunkPos{ 1, 0, 1 });
                                const isInitChunk111 = world.isInitChunkFromPos(chunk_pos + world.ChunkPos{ 1, 1, 1 });

                                if ((block_pos[0] < chunk_w - 1 and block_pos[1] < chunk_w - 1 and block_pos[2] < chunk_w - 1) or
                                    (block_pos[1] < chunk_w - 1 and block_pos[2] < chunk_w - 1 and isInitChunk100) or
                                    (block_pos[0] < chunk_w - 1 and block_pos[2] < chunk_w - 1 and isInitChunk010) or
                                    (block_pos[0] < chunk_w - 1 and block_pos[1] < chunk_w - 1 and isInitChunk001) or
                                    (block_pos[2] < chunk_w - 1 and isInitChunk100 and isInitChunk010 and isInitChunk110) or
                                    (block_pos[1] < chunk_w - 1 and isInitChunk100 and isInitChunk001 and isInitChunk101) or
                                    (block_pos[0] < chunk_w - 1 and isInitChunk010 and isInitChunk001 and isInitChunk011) or
                                    (isInitChunk100 and isInitChunk010 and isInitChunk001 and isInitChunk110 and isInitChunk011 and isInitChunk101 and isInitChunk111))
                                {
                                    const absolute_block_pos = chunk_pos * world.ChunkPos{ chunk_w, chunk_w, chunk_w } + block_pos;
                                    id |= @as(u8, @intFromBool(world.getBlock(absolute_block_pos + world.BlockPos{ 0, 0, 0 }) != .air)) << 3;
                                    id |= @as(u8, @intFromBool(world.getBlock(absolute_block_pos + world.BlockPos{ 1, 0, 0 }) != .air)) << 2;
                                    id |= @as(u8, @intFromBool(world.getBlock(absolute_block_pos + world.BlockPos{ 1, 1, 0 }) != .air)) << 1;
                                    id |= @as(u8, @intFromBool(world.getBlock(absolute_block_pos + world.BlockPos{ 0, 1, 0 }) != .air)) << 0;
                                    id |= @as(u8, @intFromBool(world.getBlock(absolute_block_pos + world.BlockPos{ 0, 0, 1 }) != .air)) << 7;
                                    id |= @as(u8, @intFromBool(world.getBlock(absolute_block_pos + world.BlockPos{ 1, 0, 1 }) != .air)) << 6;
                                    id |= @as(u8, @intFromBool(world.getBlock(absolute_block_pos + world.BlockPos{ 1, 1, 1 }) != .air)) << 5;
                                    id |= @as(u8, @intFromBool(world.getBlock(absolute_block_pos + world.BlockPos{ 0, 1, 1 }) != .air)) << 4;
                                }

                                if (id == 0) continue;
                                var i: usize = 0;
                                while (_mct.vertex[id][i] < 12) : (i += 3) {
                                    const v1 = _mct.edge[_mct.vertex[id][i + 0]];
                                    const v2 = _mct.edge[_mct.vertex[id][i + 1]];
                                    const v3 = _mct.edge[_mct.vertex[id][i + 2]];

                                    const n = [3]i8{
                                        _mct.normal[id][i + 0],
                                        _mct.normal[id][i + 1],
                                        _mct.normal[id][i + 2],
                                    };

                                    s.vertex_buffer_data[len * 3 + 0] = v1[0] + @as(f32, @floatFromInt(block_pos[0]));
                                    s.vertex_buffer_data[len * 3 + 1] = v1[1] + @as(f32, @floatFromInt(block_pos[1]));
                                    s.vertex_buffer_data[len * 3 + 2] = v1[2] + @as(f32, @floatFromInt(block_pos[2]));
                                    s.vertex_buffer_data[len * 3 + 3] = v2[0] + @as(f32, @floatFromInt(block_pos[0]));
                                    s.vertex_buffer_data[len * 3 + 4] = v2[1] + @as(f32, @floatFromInt(block_pos[1]));
                                    s.vertex_buffer_data[len * 3 + 5] = v2[2] + @as(f32, @floatFromInt(block_pos[2]));
                                    s.vertex_buffer_data[len * 3 + 6] = v3[0] + @as(f32, @floatFromInt(block_pos[0]));
                                    s.vertex_buffer_data[len * 3 + 7] = v3[1] + @as(f32, @floatFromInt(block_pos[1]));
                                    s.vertex_buffer_data[len * 3 + 8] = v3[2] + @as(f32, @floatFromInt(block_pos[2]));

                                    s.normal_buffer_data[len * 3 + 0] = n[0];
                                    s.normal_buffer_data[len * 3 + 1] = n[1];
                                    s.normal_buffer_data[len * 3 + 2] = n[2];
                                    s.normal_buffer_data[len * 3 + 3] = n[0];
                                    s.normal_buffer_data[len * 3 + 4] = n[1];
                                    s.normal_buffer_data[len * 3 + 5] = n[2];
                                    s.normal_buffer_data[len * 3 + 6] = n[0];
                                    s.normal_buffer_data[len * 3 + 7] = n[1];
                                    s.normal_buffer_data[len * 3 + 8] = n[2];

                                    len += 3;
                                }
                            }
                        }
                    }

                    _data.world.chunk.vertex_buffers[world.chunkIdFromChunkPos(chunk_pos)] = try gfx.Buffer.init(.{
                        .name = "world terra chunk vertex",
                        .target = .vbo,
                        .datatype = .f32,
                        .vertsize = vertex_size,
                        .usage = .static_draw,
                    });
                    _data.world.chunk.vertex_buffers[world.chunkIdFromChunkPos(chunk_pos)].?.data(std.mem.sliceAsBytes(s.vertex_buffer_data[0 .. len * 3]));

                    _data.world.chunk.normal_buffers[world.chunkIdFromChunkPos(chunk_pos)] = try gfx.Buffer.init(.{
                        .name = "world terra chunk normal",
                        .target = .vbo,
                        .datatype = .i8,
                        .vertsize = normal_size,
                        .usage = .static_draw,
                    });
                    _data.world.chunk.normal_buffers[world.chunkIdFromChunkPos(chunk_pos)].?.data(std.mem.sliceAsBytes(s.normal_buffer_data[0 .. len * 3]));

                    _data.world.chunk.meshes[world.chunkIdFromChunkPos(chunk_pos)] = try gfx.Mesh.init(.{
                        .name = "world terra chunk mesh",
                        .buffers = &.{
                            _data.world.chunk.vertex_buffers[world.chunkIdFromChunkPos(chunk_pos)].?,
                            _data.world.chunk.normal_buffers[world.chunkIdFromChunkPos(chunk_pos)].?,
                        },
                        .vertcnt = @intCast(len),
                        .drawmode = .triangles,
                    });
                    _data.world.chunk.meshes[world.chunkIdFromChunkPos(chunk_pos)].?.draw();
                }
            }
        }
    }
}

fn drawWorldProjectile() void {
    const bytes = world.getProjectilesPosBytes();
    _data.world.projectile.vertex_buffer.subdata(0, bytes);
    _data.world.projectile.program.use();
    _data.world.projectile.uniform.model.set(zm.identity());
    _data.world.projectile.uniform.view.set(camera.view);
    _data.world.projectile.uniform.proj.set(camera.proj);
    _data.world.projectile.mesh.draw();
}

fn drawShape() void {
    drawShapeLine();
}

fn drawShapeLine() void {
    _data.shape.line.program.use();
    _data.shape.line.uniform.model.set(zm.identity());
    _data.shape.line.uniform.view.set(camera.view);
    _data.shape.line.uniform.proj.set(camera.proj);
    _data.shape.line.mesh.vertcnt = shape.getLinesMaxCnt() * 2;
    _data.shape.line.mesh.draw();
}

fn drawGui() void {
    drawGuiRect();
    drawGuiPanel();
    drawGuiButton();
    drawGuiSwitcher();
    drawGuiSlider();
    drawGuiText();
    drawGuiCursor();
}

fn drawGuiRect() void {
    _data.gui.rect.program.use();
    _data.gui.rect.uniform.vpsize.set(window.size);
    _data.gui.rect.uniform.scale.set(gui.scale);
}

fn drawGuiPanel() void {
    _data.gui.panel.texture.use();
    for (gui.panels.items) |item| {
        if (gui.menus.items[item.menu].show) {
            _data.gui.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
            _data.gui.rect.uniform.texrect.set(@Vector(4, i32){
                0,
                0,
                @intCast(_data.gui.panel.texture.size[0]),
                @intCast(_data.gui.panel.texture.size[1]),
            });
            _data.gui.rect.mesh.draw();
        }
    }
}

fn drawGuiButton() void {
    _data.gui.button.texture.use();
    for (gui.buttons.items) |item| {
        if (gui.menus.items[item.menu].show) {
            _data.gui.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
            switch (item.state) {
                .empty => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 8, 8 }),
                .focus => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 8, 0, 16, 8 }),
                .press => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 16, 0, 24, 8 }),
            }
            _data.gui.rect.mesh.draw();
        }
    }
}

fn drawGuiSwitcher() void {
    _data.gui.switcher.texture.use();
    for (gui.switchers.items) |item| {
        if (gui.menus.items[item.menu].show) {
            _data.gui.rect.uniform.rect.set(
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
                .empty => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 6, 8 }),
                .focus => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 6, 0, 12, 8 }),
                .press => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 12, 0, 18, 8 }),
            }
            _data.gui.rect.mesh.draw();

            _data.gui.rect.uniform.rect.set(
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
                .empty => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 0, 8, 4, 16 }),
                .focus => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 6, 8, 10, 16 }),
                .press => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 12, 8, 16, 16 }),
            }
            _data.gui.rect.mesh.draw();
        }
    }
}

fn drawGuiSlider() void {
    _data.gui.slider.texture.use();
    _data.gui.rect.uniform.vpsize.set(window.size);
    _data.gui.rect.uniform.scale.set(gui.scale);
    for (gui.sliders.items) |item| {
        if (gui.menus.items[item.menu].show) {
            _data.gui.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
            switch (item.state) {
                .empty => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 6, 8 }),
                .focus => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 6, 0, 12, 8 }),
                .press => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 12, 0, 18, 8 }),
            }
            _data.gui.rect.mesh.draw();

            const len: f32 = @floatFromInt(item.rect.scale(gui.scale).size()[0] - 6 * gui.scale);
            const pos: i32 = @intFromFloat(item.value * len);
            _data.gui.rect.uniform.rect.set(
                item.alignment.transform(gui.Rect{
                    .min = item.rect.min * gui.Size{ gui.scale, gui.scale } + gui.Pos{ pos, 0 },
                    .max = .{
                        item.rect.min[0] * gui.scale + pos + 6 * gui.scale,
                        item.rect.max[1] * gui.scale,
                    },
                }, window.size).vector(),
            );
            switch (item.state) {
                .empty => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 0, 8, 6, 16 }),
                .focus => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 6, 8, 12, 16 }),
                .press => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 12, 8, 18, 16 }),
            }
            _data.gui.rect.mesh.draw();
        }
    }
}

fn drawGuiText() void {
    _data.gui.text.program.use();
    _data.gui.text.texture.use();
    _data.gui.text.uniform.vpsize.set(window.size);
    _data.gui.text.uniform.scale.set(gui.scale);
    _data.gui.text.uniform.color.set(gui.Color{ 1.0, 1.0, 1.0, 1.0 });
    for (gui.texts.items) |item| {
        if (gui.menus.items[item.menu].show) {
            const pos = item.alignment.transform(item.rect.scale(gui.scale), window.size).min;
            var offset: i32 = 0;
            for (item.data) |cid| {
                if (cid == ' ') {
                    offset += 3 * gui.scale;
                    continue;
                }
                _data.gui.text.uniform.pos.set(gui.Pos{ pos[0] + offset, pos[1] });
                _data.gui.text.uniform.tex.set(gui.Pos{ gui.font.chars[cid].pos, gui.font.chars[cid].width });
                _data.gui.rect.mesh.draw();
                offset += (gui.font.chars[cid].width + 1) * gui.scale;
            }
        }
    }
}

fn drawGuiCursor() void {
    _data.gui.rect.program.use();
    _data.gui.cursor.texture.use();
    const p1 = 4 * gui.scale - @divTrunc(gui.scale, 2);
    const p2 = 3 * gui.scale + @divTrunc(gui.scale, 2);
    _data.gui.rect.uniform.rect.set((gui.Rect{
        .min = gui.cursor.pos - gui.Pos{ p1, p1 },
        .max = gui.cursor.pos + gui.Pos{ p2, p2 },
    }).vector());
    switch (gui.cursor.press) {
        false => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 7, 7 }),
        true => _data.gui.rect.uniform.texrect.set(@Vector(4, i32){ 7, 0, 14, 7 }),
    }
    _data.gui.rect.mesh.draw();
}
