const std = @import("std");
const zm = @import("zmath");
const gl = @import("zopengl").bindings;

const config = @import("config.zig");
const window = @import("window.zig");
const camera = @import("camera.zig");
const world = @import("world.zig");
const gfx = @import("gfx.zig");
const gui = @import("gui.zig");
const data = @import("drawer/data.zig");
const mct = @import("drawer/mct.zig");

const log = std.log.scoped(.drawer);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;
const Mat = zm.Mat;
const Vec = zm.Vec;
const Color = Vec;

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

    try data.init(_allocator);
}

pub fn deinit() void {
    data.deinit();
}

pub fn draw() !void {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.clearColor(
        config.drawer.background.color[0],
        config.drawer.background.color[1],
        config.drawer.background.color[2],
        config.drawer.background.color[3],
    );
    gl.enable(gl.DEPTH_TEST);
    gl.polygonMode(gl.FRONT_AND_BACK, if (config.debug.show_grid) gl.LINE else gl.FILL);

    { // WORLD
        { // TERRA
            { // CHUNK
                const terra = world.terra;
                const terra_h = terra.h;
                const terra_w = terra.w;
                const chunk_w = terra.Chunk.w;
                const vertex_size = 3;
                const normal_size = 3;
                const s = struct {
                    var vertex_buffer_data = [1]f32{0.0} ** (1024 * 1024 * vertex_size);
                    var normal_buffer_data = [1]i8{0} ** (1024 * 1024 * normal_size);
                };

                data.terra.chunk.program.use();
                data.terra.chunk.texture.dirt.use();
                data.terra.chunk.uniform.model.set(zm.identity());
                data.terra.chunk.uniform.view.set(camera.view);
                data.terra.chunk.uniform.proj.set(camera.proj);
                data.terra.chunk.uniform.light.color.set(config.drawer.light.color);
                data.terra.chunk.uniform.light.direction.set(config.drawer.light.direction);
                data.terra.chunk.uniform.light.ambient.set(config.drawer.light.ambient);
                data.terra.chunk.uniform.light.diffuse.set(config.drawer.light.diffuse);
                data.terra.chunk.uniform.light.specular.set(config.drawer.light.specular);
                data.terra.chunk.uniform.chunk.width.set(@as(f32, @floatFromInt(chunk_w)));

                var chunk_pos = terra.Chunk.Pos{ 0, 0, 0 };
                while (chunk_pos[2] < terra_h) : (chunk_pos[2] += 1) {
                    chunk_pos[1] = 0;
                    while (chunk_pos[1] < terra_w) : (chunk_pos[1] += 1) {
                        chunk_pos[0] = 0;
                        while (chunk_pos[0] < terra_w) : (chunk_pos[0] += 1) {
                            data.terra.chunk.uniform.chunk.pos.set(@Vector(3, f32){ @floatFromInt(chunk_pos[0]), @floatFromInt(chunk_pos[1]), @floatFromInt(chunk_pos[2]) });
                            if (data.terra.chunk.meshes[terra.chunkIndexFromChunkPos(chunk_pos)]) |mesh| {
                                mesh.draw();
                            } else if (terra.isInitChunk(chunk_pos)) {
                                var len: usize = 0;
                                var block_pos = terra.Block.Pos{ 0, 0, 0 };
                                while (block_pos[2] < chunk_w) : (block_pos[2] += 1) {
                                    block_pos[1] = 0;
                                    while (block_pos[1] < chunk_w) : (block_pos[1] += 1) {
                                        block_pos[0] = 0;
                                        while (block_pos[0] < chunk_w) : (block_pos[0] += 1) {
                                            var index: u8 = 0;

                                            const isInitChunk100 = terra.isInitChunk(chunk_pos + terra.Chunk.Pos{ 1, 0, 0 });
                                            const isInitChunk010 = terra.isInitChunk(chunk_pos + terra.Chunk.Pos{ 0, 1, 0 });
                                            const isInitChunk001 = terra.isInitChunk(chunk_pos + terra.Chunk.Pos{ 0, 0, 1 });
                                            const isInitChunk110 = terra.isInitChunk(chunk_pos + terra.Chunk.Pos{ 1, 1, 0 });
                                            const isInitChunk011 = terra.isInitChunk(chunk_pos + terra.Chunk.Pos{ 0, 1, 1 });
                                            const isInitChunk101 = terra.isInitChunk(chunk_pos + terra.Chunk.Pos{ 1, 0, 1 });
                                            const isInitChunk111 = terra.isInitChunk(chunk_pos + terra.Chunk.Pos{ 1, 1, 1 });

                                            if ((block_pos[0] < chunk_w - 1 and block_pos[1] < chunk_w - 1 and block_pos[2] < chunk_w - 1) or
                                                (block_pos[1] < chunk_w - 1 and block_pos[2] < chunk_w - 1 and isInitChunk100) or
                                                (block_pos[0] < chunk_w - 1 and block_pos[2] < chunk_w - 1 and isInitChunk010) or
                                                (block_pos[0] < chunk_w - 1 and block_pos[1] < chunk_w - 1 and isInitChunk001) or
                                                (block_pos[2] < chunk_w - 1 and isInitChunk100 and isInitChunk010 and isInitChunk110) or
                                                (block_pos[1] < chunk_w - 1 and isInitChunk100 and isInitChunk001 and isInitChunk101) or
                                                (block_pos[0] < chunk_w - 1 and isInitChunk010 and isInitChunk001 and isInitChunk011) or
                                                (isInitChunk100 and isInitChunk010 and isInitChunk001 and isInitChunk110 and isInitChunk011 and isInitChunk101 and isInitChunk111))
                                            {
                                                const absolute_block_pos = chunk_pos * terra.Chunk.Pos{ chunk_w, chunk_w, chunk_w } + block_pos;
                                                index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.Block.Pos{ 0, 0, 0 }).id > 0)) << 3;
                                                index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.Block.Pos{ 1, 0, 0 }).id > 0)) << 2;
                                                index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.Block.Pos{ 1, 1, 0 }).id > 0)) << 1;
                                                index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.Block.Pos{ 0, 1, 0 }).id > 0)) << 0;
                                                index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.Block.Pos{ 0, 0, 1 }).id > 0)) << 7;
                                                index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.Block.Pos{ 1, 0, 1 }).id > 0)) << 6;
                                                index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.Block.Pos{ 1, 1, 1 }).id > 0)) << 5;
                                                index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.Block.Pos{ 0, 1, 1 }).id > 0)) << 4;
                                            }

                                            if (index == 0) continue;
                                            var i: usize = 0;
                                            while (mct.vertex[index][i] < 12) : (i += 3) {
                                                const v1 = mct.edge[mct.vertex[index][i + 0]];
                                                const v2 = mct.edge[mct.vertex[index][i + 1]];
                                                const v3 = mct.edge[mct.vertex[index][i + 2]];
                                                const n = [3]i8{
                                                    mct.normal[index][i + 0],
                                                    mct.normal[index][i + 1],
                                                    mct.normal[index][i + 2],
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

                                data.terra.chunk.vertex_buffers[terra.chunkIndexFromChunkPos(chunk_pos)] = try gfx.Buffer.init(.{
                                    .name = "world terra chunk vertex",
                                    .target = .vbo,
                                    .datatype = .f32,
                                    .vertsize = vertex_size,
                                    .usage = .static_draw,
                                });
                                data.terra.chunk.vertex_buffers[terra.chunkIndexFromChunkPos(chunk_pos)].?.data(std.mem.sliceAsBytes(s.vertex_buffer_data[0 .. len * 3]));

                                data.terra.chunk.normal_buffers[terra.chunkIndexFromChunkPos(chunk_pos)] = try gfx.Buffer.init(.{
                                    .name = "world terra chunk normal",
                                    .target = .vbo,
                                    .datatype = .i8,
                                    .vertsize = normal_size,
                                    .usage = .static_draw,
                                });
                                data.terra.chunk.normal_buffers[terra.chunkIndexFromChunkPos(chunk_pos)].?.data(std.mem.sliceAsBytes(s.normal_buffer_data[0 .. len * 3]));

                                data.terra.chunk.meshes[terra.chunkIndexFromChunkPos(chunk_pos)] = try gfx.Mesh.init(.{
                                    .name = "world terra chunk mesh",
                                    .buffers = &.{
                                        data.terra.chunk.vertex_buffers[terra.chunkIndexFromChunkPos(chunk_pos)].?,
                                        data.terra.chunk.normal_buffers[terra.chunkIndexFromChunkPos(chunk_pos)].?,
                                    },
                                    .vertcnt = @intCast(len),
                                    .drawmode = .triangles,
                                });
                                data.terra.chunk.meshes[terra.chunkIndexFromChunkPos(chunk_pos)].?.draw();
                            }
                        }
                    }
                }
            }
        }

        { // ENTITY
            { // ACTOR

            }

            { // BULLETS
                data.entity.bullet.vertex_buffer.subdata(0, world.entity.bullets.getPosBytes());
                data.entity.bullet.program.use();
                data.entity.bullet.uniform.model.set(zm.identity());
                data.entity.bullet.uniform.view.set(camera.view);
                data.entity.bullet.uniform.proj.set(camera.proj);
                data.entity.bullet.mesh.draw();
            }
        }

        gl.disable(gl.DEPTH_TEST);

        { // SHAPE
            { // LINE
                data.shape.line.program.use();
                data.shape.line.uniform.model.set(zm.identity());
                data.shape.line.uniform.view.set(camera.view);
                data.shape.line.uniform.proj.set(camera.proj);
                data.shape.line.mesh.vertcnt = @intCast(world.shape.lines.cnt * 2);
                data.shape.line.mesh.draw();
            }
        }
    }

    { // GUI
        gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);

        { // RECT
            data.rect.program.use();
            data.rect.uniform.vpsize.set(window.size);
            data.rect.uniform.scale.set(gui.scale);
        }

        { // PANEL
            data.panel.texture.use();
            for (gui.panels.items) |item| {
                if (gui.menus.items[item.menu].show) {
                    data.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
                    data.rect.uniform.texrect.set(@Vector(4, i32){
                        0,
                        0,
                        @intCast(data.panel.texture.size[0]),
                        @intCast(data.panel.texture.size[1]),
                    });
                    data.rect.mesh.draw();
                }
            }
        }

        { // BUTTON
            data.button.texture.use();
            for (gui.buttons.items) |item| {
                if (gui.menus.items[item.menu].show) {
                    data.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
                    switch (item.state) {
                        .empty => data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 8, 8 }),
                        .focus => data.rect.uniform.texrect.set(@Vector(4, i32){ 8, 0, 16, 8 }),
                        .press => data.rect.uniform.texrect.set(@Vector(4, i32){ 16, 0, 24, 8 }),
                    }
                    data.rect.mesh.draw();
                }
            }
        }

        { // SWITCHER
            data.switcher.texture.use();
            for (gui.switchers.items) |item| {
                if (gui.menus.items[item.menu].show) {
                    data.rect.uniform.rect.set(
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
                        .empty => data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 6, 8 }),
                        .focus => data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 0, 12, 8 }),
                        .press => data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 0, 18, 8 }),
                    }
                    data.rect.mesh.draw();

                    data.rect.uniform.rect.set(
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
                        .empty => data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 8, 4, 16 }),
                        .focus => data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 8, 10, 16 }),
                        .press => data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 8, 16, 16 }),
                    }
                    data.rect.mesh.draw();
                }
            }
        }

        { // SLIDER
            data.slider.texture.use();
            data.rect.uniform.vpsize.set(window.size);
            data.rect.uniform.scale.set(gui.scale);
            for (gui.sliders.items) |item| {
                if (gui.menus.items[item.menu].show) {
                    data.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
                    switch (item.state) {
                        .empty => data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 6, 8 }),
                        .focus => data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 0, 12, 8 }),
                        .press => data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 0, 18, 8 }),
                    }
                    data.rect.mesh.draw();

                    const len: f32 = @floatFromInt(item.rect.scale(gui.scale).size()[0] - 6 * gui.scale);
                    const pos: i32 = @intFromFloat(item.value * len);
                    data.rect.uniform.rect.set(
                        item.alignment.transform(gui.Rect{
                            .min = item.rect.min * gui.Size{ gui.scale, gui.scale } + gui.Pos{ pos, 0 },
                            .max = .{
                                item.rect.min[0] * gui.scale + pos + 6 * gui.scale,
                                item.rect.max[1] * gui.scale,
                            },
                        }, window.size).vector(),
                    );
                    switch (item.state) {
                        .empty => data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 8, 6, 16 }),
                        .focus => data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 8, 12, 16 }),
                        .press => data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 8, 18, 16 }),
                    }
                    data.rect.mesh.draw();
                }
            }
        }

        { // TEXT
            data.text.program.use();
            data.text.texture.use();
            data.text.uniform.vpsize.set(window.size);
            data.text.uniform.scale.set(gui.scale);
            data.text.uniform.color.set(gui.Color{ 1.0, 1.0, 1.0, 1.0 });
            for (gui.texts.items) |item| {
                if (gui.menus.items[item.menu].show) {
                    const pos = item.alignment.transform(item.rect.scale(gui.scale), window.size).min;
                    var offset: i32 = 0;
                    for (item.data) |cid| {
                        if (cid == ' ') {
                            offset += 3 * gui.scale;
                            continue;
                        }
                        data.text.uniform.pos.set(gui.Pos{ pos[0] + offset, pos[1] });
                        data.text.uniform.tex.set(gui.Pos{ gui.font.chars[cid].pos, gui.font.chars[cid].width });
                        data.rect.mesh.draw();
                        offset += (gui.font.chars[cid].width + 1) * gui.scale;
                    }
                }
            }
        }

        { // CURSOR
            data.rect.program.use();
            data.cursor.texture.use();
            const p1 = 4 * gui.scale - @divTrunc(gui.scale, 2);
            const p2 = 3 * gui.scale + @divTrunc(gui.scale, 2);
            data.rect.uniform.rect.set((gui.Rect{
                .min = gui.cursor.pos - gui.Pos{ p1, p1 },
                .max = gui.cursor.pos + gui.Pos{ p2, p2 },
            }).vector());
            switch (gui.cursor.press) {
                false => data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 7, 7 }),
                true => data.rect.uniform.texrect.set(@Vector(4, i32){ 7, 0, 14, 7 }),
            }
            data.rect.mesh.draw();
        }
    }
}
