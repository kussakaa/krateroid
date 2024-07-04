const std = @import("std");
const log = std.log.scoped(.drawerGui);

const zm = @import("zmath");

const gfx = @import("../gfx.zig");
const config = @import("../config.zig");
const camera = @import("../camera.zig");
const terra = @import("../terra.zig");
const mctable = @import("terra/mctable.zig");

const Allocator = std.mem.Allocator;

const data = struct {
    var vertex_buffers: [terra.Chunks.v]gfx.Buffer = undefined;
    var normal_buffers: [terra.Chunks.v]gfx.Buffer = undefined;
    var texture_buffers: [terra.Chunks.v]gfx.Buffer = undefined;
    var meshes: [terra.Chunks.v]?gfx.Mesh = undefined;

    var program: gfx.Program = undefined;
    const uniform = struct {
        var model: gfx.Uniform = undefined;
        var view: gfx.Uniform = undefined;
        var proj: gfx.Uniform = undefined;
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

    const texture = struct {
        var stone: gfx.Texture = undefined;
        var dirt: gfx.Texture = undefined;
        var sand: gfx.Texture = undefined;
    };
};

pub fn init(allocator: Allocator) !void {
    @memset(data.meshes[0..], null);

    data.program = try gfx.Program.init("terra");

    data.uniform.model = try gfx.Uniform.init(data.program, "model");
    data.uniform.view = try gfx.Uniform.init(data.program, "view");
    data.uniform.proj = try gfx.Uniform.init(data.program, "proj");

    data.uniform.light.color = try gfx.Uniform.init(data.program, "light.color");
    data.uniform.light.direction = try gfx.Uniform.init(data.program, "light.direction");
    data.uniform.light.ambient = try gfx.Uniform.init(data.program, "light.ambient");
    data.uniform.light.diffuse = try gfx.Uniform.init(data.program, "light.diffuse");
    data.uniform.light.specular = try gfx.Uniform.init(data.program, "light.specular");

    data.uniform.chunk.width = try gfx.Uniform.init(data.program, "chunk.width");
    data.uniform.chunk.pos = try gfx.Uniform.init(data.program, "chunk.pos");

    data.texture.stone = try gfx.Texture.init(allocator, "terra/stone.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
    data.texture.dirt = try gfx.Texture.init(allocator, "terra/dirt.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
    data.texture.sand = try gfx.Texture.init(allocator, "terra/sand.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
}

pub fn deinit() void {
    data.texture.dirt.deinit();
    data.texture.sand.deinit();
    data.texture.stone.deinit();
    data.program.deinit();

    for (data.meshes, 0..) |item, i| {
        if (item) |mesh| {
            mesh.deinit();
            data.vertex_buffers[i].deinit();
            data.normal_buffers[i].deinit();
            data.texture_buffers[i].deinit();
        }
    }
}

pub fn draw() !void {
    const vertex_size = 3;
    const normal_size = 3;
    const s = struct {
        var vertex_bufferdata = [1]f32{0.0} ** (1024 * 1024 * vertex_size);
        var normal_bufferdata = [1]i8{0} ** (1024 * 1024 * normal_size);
        var texture_bufferdata = [1]u8{0} ** (1024 * 1024);
    };

    data.program.use();

    data.uniform.model.set(zm.identity());
    data.uniform.view.set(camera.view);
    data.uniform.proj.set(camera.proj);

    data.uniform.light.color.set(config.drawer.light.color);
    data.uniform.light.direction.set(config.drawer.light.direction);
    data.uniform.light.ambient.set(config.drawer.light.ambient);
    data.uniform.light.diffuse.set(config.drawer.light.diffuse);
    data.uniform.light.specular.set(config.drawer.light.specular);

    data.uniform.chunk.width.set(@as(f32, @floatFromInt(terra.Chunk.w)));

    data.texture.stone.bind(0);
    data.texture.dirt.bind(1);
    data.texture.sand.bind(2);

    var chunk_pos = @Vector(2, u32){ 0, 0 };
    while (chunk_pos[1] < 8) : (chunk_pos[1] += 1) {
        chunk_pos[0] = 0;
        while (chunk_pos[0] < 8) : (chunk_pos[0] += 1) {
            data.uniform.chunk.pos.set(@Vector(3, f32){
                @floatFromInt(chunk_pos[0]),
                @floatFromInt(chunk_pos[1]),
                0.0,
            });

            const chunk_index: usize = chunk_pos[0] + chunk_pos[1] * terra.Chunks.w;

            if (data.meshes[chunk_index]) |mesh| {
                mesh.draw();
            } else {
                var len: usize = 0;
                var block_pos = @Vector(3, u32){ 0, 0, 0 };
                while (block_pos[2] < terra.Chunk.h - 1) : (block_pos[2] += 1) {
                    block_pos[1] = 0;
                    while (block_pos[1] < terra.Chunk.w) : (block_pos[1] += 1) {
                        block_pos[0] = 0;
                        while (block_pos[0] < terra.Chunk.w) : (block_pos[0] += 1) {
                            var index: u8 = 0;

                            const absolute_block_pos = block_pos + @Vector(3, u32){ chunk_pos[0] * terra.Chunk.w, chunk_pos[1] * terra.Chunk.w, 0 };

                            index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + @Vector(3, u32){ 0, 0, 0 }) != .air)) << 3;
                            index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + @Vector(3, u32){ 1, 0, 0 }) != .air)) << 2;
                            index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + @Vector(3, u32){ 1, 1, 0 }) != .air)) << 1;
                            index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + @Vector(3, u32){ 0, 1, 0 }) != .air)) << 0;
                            index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + @Vector(3, u32){ 0, 0, 1 }) != .air)) << 7;
                            index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + @Vector(3, u32){ 1, 0, 1 }) != .air)) << 6;
                            index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + @Vector(3, u32){ 1, 1, 1 }) != .air)) << 5;
                            index |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + @Vector(3, u32){ 0, 1, 1 }) != .air)) << 4;

                            if (index == 0) continue;

                            var i: usize = 0;
                            while (mctable.vertex[index][i] < 12) : (i += 3) {
                                const vindex = [3]u8{
                                    mctable.vertex[index][i + 0],
                                    mctable.vertex[index][i + 1],
                                    mctable.vertex[index][i + 2],
                                };

                                const v1 = mctable.vertex_edge[vindex[0]];
                                const v2 = mctable.vertex_edge[vindex[1]];
                                const v3 = mctable.vertex_edge[vindex[2]];

                                const n = [3]i8{
                                    mctable.normal[index][i + 0],
                                    mctable.normal[index][i + 1],
                                    mctable.normal[index][i + 2],
                                };

                                const t = [3]u8{
                                    @max(
                                        @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vindex[0]][0])),
                                        @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vindex[0]][1])),
                                    ),
                                    @max(
                                        @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vindex[1]][0])),
                                        @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vindex[1]][1])),
                                    ),
                                    @max(
                                        @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vindex[2]][0])),
                                        @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vindex[2]][1])),
                                    ),
                                };

                                s.vertex_bufferdata[len * 3 + 0] = v1[0] + @as(f32, @floatFromInt(block_pos[0]));
                                s.vertex_bufferdata[len * 3 + 1] = v1[1] + @as(f32, @floatFromInt(block_pos[1]));
                                s.vertex_bufferdata[len * 3 + 2] = v1[2] + @as(f32, @floatFromInt(block_pos[2]));
                                s.vertex_bufferdata[len * 3 + 3] = v2[0] + @as(f32, @floatFromInt(block_pos[0]));
                                s.vertex_bufferdata[len * 3 + 4] = v2[1] + @as(f32, @floatFromInt(block_pos[1]));
                                s.vertex_bufferdata[len * 3 + 5] = v2[2] + @as(f32, @floatFromInt(block_pos[2]));
                                s.vertex_bufferdata[len * 3 + 6] = v3[0] + @as(f32, @floatFromInt(block_pos[0]));
                                s.vertex_bufferdata[len * 3 + 7] = v3[1] + @as(f32, @floatFromInt(block_pos[1]));
                                s.vertex_bufferdata[len * 3 + 8] = v3[2] + @as(f32, @floatFromInt(block_pos[2]));

                                s.normal_bufferdata[len * 3 + 0] = n[0];
                                s.normal_bufferdata[len * 3 + 1] = n[1];
                                s.normal_bufferdata[len * 3 + 2] = n[2];
                                s.normal_bufferdata[len * 3 + 3] = n[0];
                                s.normal_bufferdata[len * 3 + 4] = n[1];
                                s.normal_bufferdata[len * 3 + 5] = n[2];
                                s.normal_bufferdata[len * 3 + 6] = n[0];
                                s.normal_bufferdata[len * 3 + 7] = n[1];
                                s.normal_bufferdata[len * 3 + 8] = n[2];

                                s.texture_bufferdata[len + 0] = t[0] - 1;
                                s.texture_bufferdata[len + 1] = t[1] - 1;
                                s.texture_bufferdata[len + 2] = t[2] - 1;

                                len += 3;
                            }
                        }
                    }
                }

                data.vertex_buffers[chunk_index] = try gfx.Buffer.init(.{
                    .name = "terra chunk vertex",
                    .target = .vbo,
                    .datatype = .f32,
                    .vertsize = vertex_size,
                    .usage = .static_draw,
                });
                data.vertex_buffers[chunk_index].data(std.mem.sliceAsBytes(s.vertex_bufferdata[0..(len * 3)]));

                data.normal_buffers[chunk_index] = try gfx.Buffer.init(.{
                    .name = "terra chunk normal",
                    .target = .vbo,
                    .datatype = .i8,
                    .vertsize = normal_size,
                    .usage = .static_draw,
                });
                data.normal_buffers[chunk_index].data(std.mem.sliceAsBytes(s.normal_bufferdata[0..(len * 3)]));

                data.texture_buffers[chunk_index] = try gfx.Buffer.init(.{
                    .name = "terra chunk texture",
                    .target = .vbo,
                    .datatype = .u8,
                    .vertsize = 1,
                    .usage = .static_draw,
                });
                data.texture_buffers[chunk_index].data(std.mem.sliceAsBytes(s.texture_bufferdata[0..len]));

                data.meshes[chunk_index] = try gfx.Mesh.init(.{
                    .name = "terra chunk mesh",
                    .buffers = &.{
                        data.vertex_buffers[chunk_index],
                        data.normal_buffers[chunk_index],
                        data.texture_buffers[chunk_index],
                    },
                    .vertcnt = @intCast(len),
                    .drawmode = .triangles,
                });
            }
        }
    }
}
