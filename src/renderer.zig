//// Преотрисовка объекта
//// ========================================
//fn render(self: *Renderer, obj: anytype) void {
//    switch (@TypeOf(obj)) {
//        world.Chunk => {
//            @setRuntimeSafety(false);
//
//            const S = struct {
//                var vertices = [1]f32{0.0} ** 4194304;
//            };
//            var chunk_id: usize = 0;
//            while (chunk_id < self.world.chunks.len) : (chunk_id += 1) {
//                if (self.world.chunks[chunk_id] == null) continue;
//                if (obj.pos[0] == self.world.chunks[chunk_id].?.pos[0] and
//                    obj.pos[1] == self.world.chunks[chunk_id].?.pos[1])
//                {
//                    if (obj.edit == self.world.chunks[chunk_id].?.edit) {
//                        return;
//                    } else {
//                        self.world.chunks[chunk_id].?.mesh.deinit();
//                    }
//                    break;
//                }
//            }
//
//            if (chunk_id == self.world.chunks.len) {
//                chunk_id = 0;
//                while (chunk_id < self.world.chunks.len) : (chunk_id += 1) {
//                    if (self.world.chunks[chunk_id] == null) {
//                        break;
//                    }
//                }
//            }
//
//            const chunk_01 = obj.world.getChunk(.{ obj.pos[0] + 1, obj.pos[1] });
//            const chunk_10 = obj.world.getChunk(.{ obj.pos[0], obj.pos[1] + 1 });
//            const chunk_11 = obj.world.getChunk(.{ obj.pos[0] + 1, obj.pos[1] + 1 });
//
//            const width = world.Chunk.width;
//            const height = world.Chunk.height;
//
//            var vertcnt: usize = 0;
//            const vertsize: usize = 6;
//
//            var z: usize = 0;
//            while (z < height - 1) : (z += 1) {
//                var y: usize = 0;
//                while (y < width) : (y += 1) {
//                    var x: usize = 0;
//                    while (x < width) : (x += 1) {
//                        var index: usize = 0;
//
//                        if (x < width - 1 and y < width - 1) {
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x] == world.Cell.block))) << 3;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x + 1] == world.Cell.block))) << 2;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y + 1][x + 1] == world.Cell.block))) << 1;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y + 1][x] == world.Cell.block))) << 0;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x] == world.Cell.block))) << 7;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x + 1] == world.Cell.block))) << 6;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y + 1][x + 1] == world.Cell.block))) << 5;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y + 1][x] == world.Cell.block))) << 4;
//                        } else if (x == width - 1 and y < width - 1 and chunk_01 != null) {
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x] == world.Cell.block))) << 3;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z][y][0] == world.Cell.block))) << 2;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z][y + 1][0] == world.Cell.block))) << 1;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y + 1][x] == world.Cell.block))) << 0;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x] == world.Cell.block))) << 7;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z + 1][y][0] == world.Cell.block))) << 6;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z + 1][y + 1][0] == world.Cell.block))) << 5;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y + 1][x] == world.Cell.block))) << 4;
//                        } else if (x < width - 1 and y == width - 1 and chunk_10 != null) {
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x] == world.Cell.block))) << 3;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x + 1] == world.Cell.block))) << 2;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z][0][x + 1] == world.Cell.block))) << 1;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z][0][x] == world.Cell.block))) << 0;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x] == world.Cell.block))) << 7;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x + 1] == world.Cell.block))) << 6;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z + 1][0][x + 1] == world.Cell.block))) << 5;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z + 1][0][x] == world.Cell.block))) << 4;
//                        } else if (chunk_01 != null and chunk_10 != null and chunk_11 != null) {
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x] == world.Cell.block))) << 3;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z][y][0] == world.Cell.block))) << 2;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_11.?.grid[z][0][0] == world.Cell.block))) << 1;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z][0][x] == world.Cell.block))) << 0;
//                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x] == world.Cell.block))) << 7;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z + 1][y][0] == world.Cell.block))) << 6;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_11.?.grid[z + 1][0][0] == world.Cell.block))) << 5;
//                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z + 1][0][x] == world.Cell.block))) << 4;
//                        }
//
//                        if (index == 0 or index == 255) continue;
//
//                        var i: usize = 0;
//                        while (mct.tri[index][i] < 12) : (i += 3) {
//                            const p1 = mct.edge[mct.tri[index][i + 0]];
//                            const p2 = mct.edge[mct.tri[index][i + 1]];
//                            const p3 = mct.edge[mct.tri[index][i + 2]];
//                            const n = linmath.normalize(linmath.cross(p2 - p1, p3 - p1));
//
//                            S.vertices[(vertcnt + 0) * vertsize + 0] = p1[0] + @as(f32, @floatFromInt(x)) + @as(f32, @floatFromInt(obj.pos[0] * width));
//                            S.vertices[(vertcnt + 0) * vertsize + 1] = p1[1] + @as(f32, @floatFromInt(y)) + @as(f32, @floatFromInt(obj.pos[1] * width));
//                            S.vertices[(vertcnt + 0) * vertsize + 2] = p1[2] + @as(f32, @floatFromInt(z));
//                            S.vertices[(vertcnt + 0) * vertsize + 3] = n[0];
//                            S.vertices[(vertcnt + 0) * vertsize + 4] = n[1];
//                            S.vertices[(vertcnt + 0) * vertsize + 5] = n[2];
//
//                            S.vertices[(vertcnt + 1) * vertsize + 0] = p2[0] + @as(f32, @floatFromInt(x)) + @as(f32, @floatFromInt(obj.pos[0] * width));
//                            S.vertices[(vertcnt + 1) * vertsize + 1] = p2[1] + @as(f32, @floatFromInt(y)) + @as(f32, @floatFromInt(obj.pos[1] * width));
//                            S.vertices[(vertcnt + 1) * vertsize + 2] = p2[2] + @as(f32, @floatFromInt(z));
//                            S.vertices[(vertcnt + 1) * vertsize + 3] = n[0];
//                            S.vertices[(vertcnt + 1) * vertsize + 4] = n[1];
//                            S.vertices[(vertcnt + 1) * vertsize + 5] = n[2];
//
//                            S.vertices[(vertcnt + 2) * vertsize + 0] = p3[0] + @as(f32, @floatFromInt(x)) + @as(f32, @floatFromInt(obj.pos[0] * width));
//                            S.vertices[(vertcnt + 2) * vertsize + 1] = p3[1] + @as(f32, @floatFromInt(y)) + @as(f32, @floatFromInt(obj.pos[1] * width));
//                            S.vertices[(vertcnt + 2) * vertsize + 2] = p3[2] + @as(f32, @floatFromInt(z));
//                            S.vertices[(vertcnt + 2) * vertsize + 3] = n[0];
//                            S.vertices[(vertcnt + 2) * vertsize + 4] = n[1];
//                            S.vertices[(vertcnt + 2) * vertsize + 5] = n[2];
//
//                            vertcnt += 3;
//                        }
//                    }
//                }
//            }
//
//            self.world.chunks[chunk_id] = .{
//                .pos = obj.pos,
//                .edit = obj.edit,
//                .mesh = Mesh.init(S.vertices[0..(vertcnt * vertsize)], &.{ 3, 3 }),
//            };
//        },
//        else => std.debug.panic("[!FAILED!]:[RENDERER]:Impossible to render type: {}", .{@TypeOf(obj)}),
//    }
//}
//
