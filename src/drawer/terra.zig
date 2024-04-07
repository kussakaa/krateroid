const std = @import("std");
const log = std.log.scoped(.drawerGui);
const zm = @import("zmath");
const gfx = @import("../gfx.zig");
const config = @import("../config.zig");
const camera = @import("../camera.zig");
const terra = @import("../terra.zig");
const mctable = @import("terra/mctable.zig");

const Allocator = std.mem.Allocator;

const _data = struct {
    var vertex_buffers: [terra.v]gfx.Buffer = undefined;
    var normal_buffers: [terra.v]gfx.Buffer = undefined;
    var texture_buffers: [terra.v]gfx.Buffer = undefined;
    var meshes: [terra.v]?gfx.Mesh = undefined;

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
    @memset(_data.meshes[0..], null);

    _data.program = try gfx.Program.init(allocator, "terra");

    _data.uniform.model = try gfx.Uniform.init(_data.program, "model");
    _data.uniform.view = try gfx.Uniform.init(_data.program, "view");
    _data.uniform.proj = try gfx.Uniform.init(_data.program, "proj");

    _data.uniform.light.color = try gfx.Uniform.init(_data.program, "light.color");
    _data.uniform.light.direction = try gfx.Uniform.init(_data.program, "light.direction");
    _data.uniform.light.ambient = try gfx.Uniform.init(_data.program, "light.ambient");
    _data.uniform.light.diffuse = try gfx.Uniform.init(_data.program, "light.diffuse");
    _data.uniform.light.specular = try gfx.Uniform.init(_data.program, "light.specular");

    _data.uniform.chunk.width = try gfx.Uniform.init(_data.program, "chunk.width");
    _data.uniform.chunk.pos = try gfx.Uniform.init(_data.program, "chunk.pos");

    _data.texture.stone = try gfx.Texture.init(allocator, "terra/stone.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
    _data.texture.dirt = try gfx.Texture.init(allocator, "terra/dirt.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
    _data.texture.sand = try gfx.Texture.init(allocator, "terra/sand.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
}

pub fn deinit() void {
    _data.texture.dirt.deinit();
    _data.texture.sand.deinit();
    _data.texture.stone.deinit();
    _data.program.deinit();

    for (_data.meshes, 0..) |item, i| {
        if (item) |mesh| {
            mesh.deinit();
            _data.vertex_buffers[i].deinit();
            _data.normal_buffers[i].deinit();
            _data.texture_buffers[i].deinit();
        }
    }
}

pub fn draw() !void {
    const vertex_size = 3;
    const normal_size = 3;
    const s = struct {
        var vertex_buffer_data = [1]f32{0.0} ** (1024 * 1024 * vertex_size);
        var normal_buffer_data = [1]i8{0} ** (1024 * 1024 * normal_size);
        var texture_buffer_data = [1]u8{0} ** (1024 * 1024);
    };

    _data.program.use();

    _data.uniform.model.set(zm.identity());
    _data.uniform.view.set(camera.view);
    _data.uniform.proj.set(camera.proj);

    _data.uniform.light.color.set(config.drawer.light.color);
    _data.uniform.light.direction.set(config.drawer.light.direction);
    _data.uniform.light.ambient.set(config.drawer.light.ambient);
    _data.uniform.light.diffuse.set(config.drawer.light.diffuse);
    _data.uniform.light.specular.set(config.drawer.light.specular);

    _data.uniform.chunk.width.set(@as(f32, @floatFromInt(terra.chunk_w)));

    _data.texture.stone.bind(0);
    _data.texture.dirt.bind(1);
    _data.texture.sand.bind(2);

    var chunk_pos = terra.ChunkPos{ 0, 0, 0 };
    while (chunk_pos[2] < terra.h) : (chunk_pos[2] += 1) {
        chunk_pos[1] = 0;
        while (chunk_pos[1] < terra.w) : (chunk_pos[1] += 1) {
            chunk_pos[0] = 0;
            while (chunk_pos[0] < terra.w) : (chunk_pos[0] += 1) {
                _data.uniform.chunk.pos.set(@Vector(3, f32){
                    @floatFromInt(chunk_pos[0]),
                    @floatFromInt(chunk_pos[1]),
                    @floatFromInt(chunk_pos[2]),
                });

                const chunk_id = terra.chunkIdFromChunkPos(chunk_pos);

                if (_data.meshes[chunk_id]) |mesh| {
                    mesh.draw();
                } else if (terra.isInitChunk(chunk_id)) {
                    var len: usize = 0;
                    var block_pos = terra.BlockPos{ 0, 0, 0 };
                    while (block_pos[2] < terra.chunk_w) : (block_pos[2] += 1) {
                        block_pos[1] = 0;
                        while (block_pos[1] < terra.chunk_w) : (block_pos[1] += 1) {
                            block_pos[0] = 0;
                            while (block_pos[0] < terra.chunk_w) : (block_pos[0] += 1) {
                                var id: u8 = 0;

                                const absolute_block_pos = chunk_pos * terra.ChunkPos{ terra.chunk_w, terra.chunk_w, terra.chunk_w } + block_pos;

                                const isInitChunk100 = terra.isInitChunkFromPos(chunk_pos + terra.ChunkPos{ 1, 0, 0 });
                                const isInitChunk010 = terra.isInitChunkFromPos(chunk_pos + terra.ChunkPos{ 0, 1, 0 });
                                const isInitChunk001 = terra.isInitChunkFromPos(chunk_pos + terra.ChunkPos{ 0, 0, 1 });
                                const isInitChunk110 = terra.isInitChunkFromPos(chunk_pos + terra.ChunkPos{ 1, 1, 0 });
                                const isInitChunk011 = terra.isInitChunkFromPos(chunk_pos + terra.ChunkPos{ 0, 1, 1 });
                                const isInitChunk101 = terra.isInitChunkFromPos(chunk_pos + terra.ChunkPos{ 1, 0, 1 });
                                const isInitChunk111 = terra.isInitChunkFromPos(chunk_pos + terra.ChunkPos{ 1, 1, 1 });

                                if ((block_pos[0] < terra.chunk_w - 1 and block_pos[1] < terra.chunk_w - 1 and block_pos[2] < terra.chunk_w - 1) or
                                    (block_pos[1] < terra.chunk_w - 1 and block_pos[2] < terra.chunk_w - 1 and isInitChunk100) or
                                    (block_pos[0] < terra.chunk_w - 1 and block_pos[2] < terra.chunk_w - 1 and isInitChunk010) or
                                    (block_pos[0] < terra.chunk_w - 1 and block_pos[1] < terra.chunk_w - 1 and isInitChunk001) or
                                    (block_pos[2] < terra.chunk_w - 1 and isInitChunk100 and isInitChunk010 and isInitChunk110) or
                                    (block_pos[1] < terra.chunk_w - 1 and isInitChunk100 and isInitChunk001 and isInitChunk101) or
                                    (block_pos[0] < terra.chunk_w - 1 and isInitChunk010 and isInitChunk001 and isInitChunk011) or
                                    (isInitChunk100 and isInitChunk010 and isInitChunk001 and isInitChunk110 and isInitChunk011 and isInitChunk101 and isInitChunk111))
                                {
                                    id |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.BlockPos{ 0, 0, 0 }) != .air)) << 3;
                                    id |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.BlockPos{ 1, 0, 0 }) != .air)) << 2;
                                    id |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.BlockPos{ 1, 1, 0 }) != .air)) << 1;
                                    id |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.BlockPos{ 0, 1, 0 }) != .air)) << 0;
                                    id |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.BlockPos{ 0, 0, 1 }) != .air)) << 7;
                                    id |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.BlockPos{ 1, 0, 1 }) != .air)) << 6;
                                    id |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.BlockPos{ 1, 1, 1 }) != .air)) << 5;
                                    id |= @as(u8, @intFromBool(terra.getBlock(absolute_block_pos + terra.BlockPos{ 0, 1, 1 }) != .air)) << 4;
                                }

                                if (id == 0) continue;
                                var i: usize = 0;
                                while (mctable.vertex[id][i] < 12) : (i += 3) {
                                    const vid = [3]u8{
                                        mctable.vertex[id][i + 0],
                                        mctable.vertex[id][i + 1],
                                        mctable.vertex[id][i + 2],
                                    };

                                    const v1 = mctable.vertex_edge[vid[0]];
                                    const v2 = mctable.vertex_edge[vid[1]];
                                    const v3 = mctable.vertex_edge[vid[2]];

                                    const n = [3]i8{
                                        mctable.normal[id][i + 0],
                                        mctable.normal[id][i + 1],
                                        mctable.normal[id][i + 2],
                                    };

                                    const t = [3]u8{
                                        @max(
                                            @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vid[0]][0])),
                                            @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vid[0]][1])),
                                        ),
                                        @max(
                                            @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vid[1]][0])),
                                            @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vid[1]][1])),
                                        ),
                                        @max(
                                            @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vid[2]][0])),
                                            @intFromEnum(terra.getBlock(absolute_block_pos + mctable.texture_edge[vid[2]][1])),
                                        ),
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

                                    s.texture_buffer_data[len + 0] = t[0] - 1;
                                    s.texture_buffer_data[len + 1] = t[1] - 1;
                                    s.texture_buffer_data[len + 2] = t[2] - 1;

                                    len += 3;
                                }
                            }
                        }
                    }

                    _data.vertex_buffers[chunk_id] = try gfx.Buffer.init(.{
                        .name = "terra chunk vertex",
                        .target = .vbo,
                        .datatype = .f32,
                        .vertsize = vertex_size,
                        .usage = .static_draw,
                    });
                    _data.vertex_buffers[chunk_id].data(std.mem.sliceAsBytes(s.vertex_buffer_data[0..(len * 3)]));

                    _data.normal_buffers[chunk_id] = try gfx.Buffer.init(.{
                        .name = "terra chunk normal",
                        .target = .vbo,
                        .datatype = .i8,
                        .vertsize = normal_size,
                        .usage = .static_draw,
                    });
                    _data.normal_buffers[chunk_id].data(std.mem.sliceAsBytes(s.normal_buffer_data[0..(len * 3)]));

                    _data.texture_buffers[chunk_id] = try gfx.Buffer.init(.{
                        .name = "terra chunk texture",
                        .target = .vbo,
                        .datatype = .u8,
                        .vertsize = 1,
                        .usage = .static_draw,
                    });
                    _data.texture_buffers[chunk_id].data(std.mem.sliceAsBytes(s.texture_buffer_data[0..len]));

                    _data.meshes[chunk_id] = try gfx.Mesh.init(.{
                        .name = "terra chunk mesh",
                        .buffers = &.{
                            _data.vertex_buffers[chunk_id],
                            _data.normal_buffers[chunk_id],
                            _data.texture_buffers[chunk_id],
                        },
                        .vertcnt = @intCast(len),
                        .drawmode = .triangles,
                    });
                    _data.meshes[chunk_id].?.draw();
                }
            }
        }
    }
}
