const shape_quad_mesh_vertices = [_]f32{
    // +X
    0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,
    0.5,  0.5,  -0.5, 1.0,  0.0,  0.0,
    0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
    0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
    0.5,  -0.5, 0.5,  1.0,  0.0,  0.0,
    0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,
    // -X
    -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,
    -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,
    -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,
    -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,
    -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,
    // +Y
    0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,
    -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,
    -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,
    0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,
    // -Y
    -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,
    0.5,  -0.5, -0.5, 0.0,  -1.0, 0.0,
    0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,
    0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,
    -0.5, -0.5, 0.5,  0.0,  -1.0, 0.0,
    -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,
    // +Z
    -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,
    0.5,  -0.5, 0.5,  0.0,  0.0,  1.0,
    0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
    0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
    -0.5, 0.5,  0.5,  0.0,  0.0,  1.0,
    -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,
    // -Z
    -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0,
    0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0,
    0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0,
    0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0,
    -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0,
    -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0,
};

// Рисование объекта
// ========================================
pub fn draw(self: *Renderer, obj: anytype) void {
    switch (@TypeOf(obj)) {
        gui.Rect => {
            self.gui.rect.program.id.use();
            ShaderProgram.setUniform(
                self.gui.rect.program.uniforms.rect,
                gui.rectAlignOfVp(
                    obj,
                    self.gui.rect.alignment,
                    self.vpsize,
                ),
            );
            ShaderProgram.setUniform(
                self.gui.rect.program.uniforms.vpsize,
                self.vpsize,
            );
            ShaderProgram.setUniform(
                self.gui.rect.program.uniforms.color,
                self.gui.rect.color,
            );
            ShaderProgram.setUniform(
                self.gui.rect.program.uniforms.borders_width,
                self.gui.rect.border.width,
            );
            ShaderProgram.setUniform(
                self.gui.rect.program.uniforms.borders_color,
                self.gui.rect.border.color,
            );
            self.gui.rect.mesh.draw();
        },
        gui.Text => {
            var advance: i32 = 0;
            var height: i32 = 0;
            self.gui.text.program.id.use();
            glyph: for (obj.data) |char| {
                if (char == ' ') {
                    advance += 10;
                    continue :glyph;
                }
                if (char == '\n') {
                    height -= 24;
                    advance = 0;
                    continue :glyph;
                }
                for (self.gui.text.chars, 0..) |renderer_char, i| {
                    if (char == renderer_char) {
                        c.glBindTexture(c.GL_TEXTURE_2D, self.gui.text.glyphs[i].texture);
                        const min = gui.pointAlignOfVp(
                            obj.pos,
                            obj.alignment,
                            self.vpsize,
                        );
                        const max = gui.pointAlignOfVp(
                            obj.pos + self.gui.text.glyphs[i].size,
                            obj.alignment,
                            self.vpsize,
                        );
                        ShaderProgram.setUniform(self.gui.text.program.uniforms.rect, I32x4{
                            min[0] + advance + self.gui.text.glyphs[i].bearing[0],
                            min[1] + height - (max[1] - min[1] - self.gui.text.glyphs[i].bearing[1]),
                            max[0] + advance + self.gui.text.glyphs[i].bearing[0],
                            max[1] + height - (max[1] - min[1] - self.gui.text.glyphs[i].bearing[1]),
                        });
                        ShaderProgram.setUniform(self.gui.text.program.uniforms.vpsize, self.vpsize);
                        ShaderProgram.setUniform(self.gui.text.program.uniforms.color, self.gui.text.color);
                        self.gui.rect.mesh.draw();
                        advance += self.gui.text.glyphs[i].advance;
                        continue :glyph;
                    }
                }
            }
        },
        gui.Button => {
            self.gui.rect.color = .{ 0.1, 0.1, 0.1, 1.0 };
            self.gui.rect.border.width = 5;
            switch (obj.state) {
                gui.Button.State.Normal => self.gui.rect.border.color = .{ 0.2, 0.2, 0.2, 1.0 },
                gui.Button.State.Focused => self.gui.rect.border.color = .{ 0.4, 0.4, 0.4, 1.0 },
                gui.Button.State.Pushed => self.gui.rect.border.color = .{ 0.7, 0.7, 0.7, 1.0 },
            }
            const alignment = self.gui.rect.alignment;
            self.gui.rect.alignment = obj.alignment;

            self.draw(obj.rect);
            self.draw(obj.text);
            self.gui.rect.alignment = alignment;
        },
        gui.Gui => {
            for (obj.buttons.items) |button| {
                self.draw(button);
            }
        },
        shape.Line => {
            self.shape.program.id.use();
            const model = Mat{
                .{ @max(obj.p1[0], obj.p2[0]) - @min(obj.p1[0], obj.p2[0]), 0.0, 0.0, @min(obj.p1[0], obj.p2[0]) },
                .{ 0.0, @max(obj.p1[1], obj.p2[1]) - @min(obj.p1[1], obj.p2[1]), 0.0, @min(obj.p1[1], obj.p2[1]) },
                .{ 0.0, 0.0, @max(obj.p1[2], obj.p2[2]) - @min(obj.p1[2], obj.p2[2]), @min(obj.p1[2], obj.p2[2]) },
                .{ 0.0, 0.0, 0.0, 1.0 },
            };
            ShaderProgram.setUniform(self.shape.program.uniforms.model, model);
            ShaderProgram.setUniform(self.shape.program.uniforms.view, self.camera.view);
            ShaderProgram.setUniform(self.shape.program.uniforms.proj, self.camera.proj);
            ShaderProgram.setUniform(self.shape.program.uniforms.color, self.shape.color);
            ShaderProgram.setUniform(self.shape.program.uniforms.light.color, ColorRgb{ 1.0, 1.0, 1.0 });
            ShaderProgram.setUniform(self.shape.program.uniforms.light.direction, Vec3{ 0.0, 0.0, 1.0 });
            ShaderProgram.setUniform(self.shape.program.uniforms.light.diffuse, 0.0);
            ShaderProgram.setUniform(self.shape.program.uniforms.light.ambient, 1.0);
            ShaderProgram.setUniform(self.shape.program.uniforms.light.specular, 0.0);
            self.shape.line.mesh.draw();
        },
        shape.Quad => {
            self.shape.program.id.use();
            const model = linmath.mul(linmath.Pos(obj.pos), linmath.Scale(obj.size));
            ShaderProgram.setUniform(self.shape.program.uniforms.model, model);
            ShaderProgram.setUniform(self.shape.program.uniforms.view, self.camera.view);
            ShaderProgram.setUniform(self.shape.program.uniforms.proj, self.camera.proj);
            ShaderProgram.setUniform(self.shape.program.uniforms.color, self.shape.color);
            ShaderProgram.setUniform(self.shape.program.uniforms.light.color, self.light.color);
            ShaderProgram.setUniform(self.shape.program.uniforms.light.direction, self.light.direction);
            ShaderProgram.setUniform(self.shape.program.uniforms.light.diffuse, self.light.diffuse);
            ShaderProgram.setUniform(self.shape.program.uniforms.light.ambient, self.light.ambient);
            ShaderProgram.setUniform(self.shape.program.uniforms.light.specular, self.light.specular);
            self.shape.quad.mesh.draw();
        },
        world.Chunk => {
            var chunk_id: usize = 0;
            while (chunk_id < self.world.chunks.len) : (chunk_id += 1) {
                if (self.world.chunks[chunk_id] == null) continue;
                if (obj.pos[0] == self.world.chunks[chunk_id].?.pos[0] and
                    obj.pos[1] == self.world.chunks[chunk_id].?.pos[1] and
                    obj.edit == self.world.chunks[chunk_id].?.edit)
                {
                    self.shape.program.id.use();
                    ShaderProgram.setUniform(self.shape.program.uniforms.model, MatIdentity);
                    ShaderProgram.setUniform(self.shape.program.uniforms.view, self.camera.view);
                    ShaderProgram.setUniform(self.shape.program.uniforms.proj, self.camera.proj);
                    ShaderProgram.setUniform(self.shape.program.uniforms.color, self.shape.color);
                    ShaderProgram.setUniform(self.shape.program.uniforms.light.color, self.light.color);
                    ShaderProgram.setUniform(self.shape.program.uniforms.light.direction, self.light.direction);
                    ShaderProgram.setUniform(self.shape.program.uniforms.light.diffuse, self.light.diffuse);
                    ShaderProgram.setUniform(self.shape.program.uniforms.light.ambient, self.light.ambient);
                    ShaderProgram.setUniform(self.shape.program.uniforms.light.specular, self.light.specular);
                    self.world.chunks[chunk_id].?.mesh.draw();
                    return;
                }
            }
            self.render(obj);
            self.draw(obj);
        },
        else => std.debug.panic("[!FAILED!]:[RENDERER]:Impossible to draw type: {}", .{@TypeOf(obj)}),
    }
}

// Преотрисовка объекта
// ========================================
fn render(self: *Renderer, obj: anytype) void {
    switch (@TypeOf(obj)) {
        world.Chunk => {
            @setRuntimeSafety(false);

            const S = struct {
                var vertices = [1]f32{0.0} ** 4194304;
            };
            var chunk_id: usize = 0;
            while (chunk_id < self.world.chunks.len) : (chunk_id += 1) {
                if (self.world.chunks[chunk_id] == null) continue;
                if (obj.pos[0] == self.world.chunks[chunk_id].?.pos[0] and
                    obj.pos[1] == self.world.chunks[chunk_id].?.pos[1])
                {
                    if (obj.edit == self.world.chunks[chunk_id].?.edit) {
                        return;
                    } else {
                        self.world.chunks[chunk_id].?.mesh.deinit();
                    }
                    break;
                }
            }

            if (chunk_id == self.world.chunks.len) {
                chunk_id = 0;
                while (chunk_id < self.world.chunks.len) : (chunk_id += 1) {
                    if (self.world.chunks[chunk_id] == null) {
                        break;
                    }
                }
            }

            const chunk_01 = obj.world.getChunk(.{ obj.pos[0] + 1, obj.pos[1] });
            const chunk_10 = obj.world.getChunk(.{ obj.pos[0], obj.pos[1] + 1 });
            const chunk_11 = obj.world.getChunk(.{ obj.pos[0] + 1, obj.pos[1] + 1 });

            const width = world.Chunk.width;
            const height = world.Chunk.height;

            var vertcnt: usize = 0;
            const vertsize: usize = 6;

            var z: usize = 0;
            while (z < height - 1) : (z += 1) {
                var y: usize = 0;
                while (y < width) : (y += 1) {
                    var x: usize = 0;
                    while (x < width) : (x += 1) {
                        var index: usize = 0;

                        if (x < width - 1 and y < width - 1) {
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x] == world.Cell.block))) << 3;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x + 1] == world.Cell.block))) << 2;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y + 1][x + 1] == world.Cell.block))) << 1;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y + 1][x] == world.Cell.block))) << 0;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x] == world.Cell.block))) << 7;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x + 1] == world.Cell.block))) << 6;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y + 1][x + 1] == world.Cell.block))) << 5;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y + 1][x] == world.Cell.block))) << 4;
                        } else if (x == width - 1 and y < width - 1 and chunk_01 != null) {
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x] == world.Cell.block))) << 3;
                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z][y][0] == world.Cell.block))) << 2;
                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z][y + 1][0] == world.Cell.block))) << 1;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y + 1][x] == world.Cell.block))) << 0;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x] == world.Cell.block))) << 7;
                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z + 1][y][0] == world.Cell.block))) << 6;
                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z + 1][y + 1][0] == world.Cell.block))) << 5;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y + 1][x] == world.Cell.block))) << 4;
                        } else if (x < width - 1 and y == width - 1 and chunk_10 != null) {
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x] == world.Cell.block))) << 3;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x + 1] == world.Cell.block))) << 2;
                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z][0][x + 1] == world.Cell.block))) << 1;
                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z][0][x] == world.Cell.block))) << 0;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x] == world.Cell.block))) << 7;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x + 1] == world.Cell.block))) << 6;
                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z + 1][0][x + 1] == world.Cell.block))) << 5;
                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z + 1][0][x] == world.Cell.block))) << 4;
                        } else if (chunk_01 != null and chunk_10 != null and chunk_11 != null) {
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z][y][x] == world.Cell.block))) << 3;
                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z][y][0] == world.Cell.block))) << 2;
                            index |= @as(u8, @intCast(@intFromBool(chunk_11.?.grid[z][0][0] == world.Cell.block))) << 1;
                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z][0][x] == world.Cell.block))) << 0;
                            index |= @as(u8, @intCast(@intFromBool(obj.grid[z + 1][y][x] == world.Cell.block))) << 7;
                            index |= @as(u8, @intCast(@intFromBool(chunk_01.?.grid[z + 1][y][0] == world.Cell.block))) << 6;
                            index |= @as(u8, @intCast(@intFromBool(chunk_11.?.grid[z + 1][0][0] == world.Cell.block))) << 5;
                            index |= @as(u8, @intCast(@intFromBool(chunk_10.?.grid[z + 1][0][x] == world.Cell.block))) << 4;
                        }

                        if (index == 0 or index == 255) continue;

                        var i: usize = 0;
                        while (mct.tri[index][i] < 12) : (i += 3) {
                            const p1 = mct.edge[mct.tri[index][i + 0]];
                            const p2 = mct.edge[mct.tri[index][i + 1]];
                            const p3 = mct.edge[mct.tri[index][i + 2]];
                            const n = linmath.normalize(linmath.cross(p2 - p1, p3 - p1));

                            S.vertices[(vertcnt + 0) * vertsize + 0] = p1[0] + @as(f32, @floatFromInt(x)) + @as(f32, @floatFromInt(obj.pos[0] * width));
                            S.vertices[(vertcnt + 0) * vertsize + 1] = p1[1] + @as(f32, @floatFromInt(y)) + @as(f32, @floatFromInt(obj.pos[1] * width));
                            S.vertices[(vertcnt + 0) * vertsize + 2] = p1[2] + @as(f32, @floatFromInt(z));
                            S.vertices[(vertcnt + 0) * vertsize + 3] = n[0];
                            S.vertices[(vertcnt + 0) * vertsize + 4] = n[1];
                            S.vertices[(vertcnt + 0) * vertsize + 5] = n[2];

                            S.vertices[(vertcnt + 1) * vertsize + 0] = p2[0] + @as(f32, @floatFromInt(x)) + @as(f32, @floatFromInt(obj.pos[0] * width));
                            S.vertices[(vertcnt + 1) * vertsize + 1] = p2[1] + @as(f32, @floatFromInt(y)) + @as(f32, @floatFromInt(obj.pos[1] * width));
                            S.vertices[(vertcnt + 1) * vertsize + 2] = p2[2] + @as(f32, @floatFromInt(z));
                            S.vertices[(vertcnt + 1) * vertsize + 3] = n[0];
                            S.vertices[(vertcnt + 1) * vertsize + 4] = n[1];
                            S.vertices[(vertcnt + 1) * vertsize + 5] = n[2];

                            S.vertices[(vertcnt + 2) * vertsize + 0] = p3[0] + @as(f32, @floatFromInt(x)) + @as(f32, @floatFromInt(obj.pos[0] * width));
                            S.vertices[(vertcnt + 2) * vertsize + 1] = p3[1] + @as(f32, @floatFromInt(y)) + @as(f32, @floatFromInt(obj.pos[1] * width));
                            S.vertices[(vertcnt + 2) * vertsize + 2] = p3[2] + @as(f32, @floatFromInt(z));
                            S.vertices[(vertcnt + 2) * vertsize + 3] = n[0];
                            S.vertices[(vertcnt + 2) * vertsize + 4] = n[1];
                            S.vertices[(vertcnt + 2) * vertsize + 5] = n[2];

                            vertcnt += 3;
                        }
                    }
                }
            }

            self.world.chunks[chunk_id] = .{
                .pos = obj.pos,
                .edit = obj.edit,
                .mesh = Mesh.init(S.vertices[0..(vertcnt * vertsize)], &.{ 3, 3 }),
            };
        },
        else => std.debug.panic("[!FAILED!]:[RENDERER]:Impossible to render type: {}", .{@TypeOf(obj)}),
    }
}
