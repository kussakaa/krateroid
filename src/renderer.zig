const std = @import("std");
const c = @import("c.zig");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");
const shape = @import("shape.zig");
const world = @import("world.zig");
const mct = @import("mct.zig");
const Allocator = std.mem.Allocator;
const Shader = @import("shader.zig").Shader;
const ShaderType = @import("shader.zig").ShaderType;
const ShaderProgram = @import("shader.zig").ShaderProgram;
const Mesh = @import("mesh.zig").Mesh;
const Camera = @import("camera.zig").Camera;

const linmath = @import("linmath.zig");
const ColorRgb = linmath.F32x3;
const ColorRgba = linmath.F32x4;
const Vec4 = linmath.F32x4;
const Vec3 = linmath.F32x3;
const I32x4 = linmath.I32x4;
const I32x2 = linmath.I32x2;
const Mat = linmath.Mat;
const MatIdentity = linmath.MatIdentity;

pub const Renderer = struct {
    allocator: Allocator,
    vpsize: I32x2 = .{ 800, 600 },
    camera: Camera = .{},
    light: struct {
        color: ColorRgb = .{ 1.0, 1.0, 1.0 },
        direction: Vec3 = .{ 0.0, 0.0, 1.0 },
        ambient: f32 = 0.4,
        diffuse: f32 = 0.3,
        specular: f32 = 0.05,
    } = .{},
    gui: struct {
        rect: struct {
            color: ColorRgba = .{ 1.0, 1.0, 1.0, 1.0 },
            alignment: gui.Alignment = gui.Alignment.left_bottom,
            border: struct {
                width: i32 = 1,
                color: ColorRgba = .{ 1.0, 1.0, 1.0, 1.0 },
            } = .{},
            program: struct {
                id: ShaderProgram,
                uniforms: struct {
                    rect: i32,
                    color: i32,
                    vpsize: i32,
                    borders_color: i32,
                    borders_width: i32,
                },
            },
            mesh: Mesh,
        },
        text: struct {
            color: ColorRgba = .{ 0.7, 0.7, 0.7, 1.0 },
            program: struct {
                id: ShaderProgram,
                uniforms: struct {
                    rect: i32,
                    vpsize: i32,
                    color: i32,
                },
            },
            chars: [100]u16,
            glyphs: [100]Glyph,
        },
    },
    shape: struct {
        color: ColorRgba = .{ 1.0, 1.0, 1.0, 1.0 },
        program: struct {
            id: ShaderProgram,
            uniforms: struct {
                model: i32,
                view: i32,
                proj: i32,
                color: i32,
                light: struct {
                    color: i32,
                    direction: i32,
                    diffuse: i32,
                    ambient: i32,
                    specular: i32,
                },
            },
        },
        line: struct {
            mesh: Mesh,
        },
        quad: struct {
            mesh: Mesh,
        },
    },
    world: struct {
        chunks: [64]?RendererChunk = [1]?RendererChunk{null} ** 64,
    } = .{},

    const Glyph = struct {
        texture: u32,
        size: I32x2,
        advance: i32,
        bearing: I32x2,
    };

    const RendererChunk = struct {
        pos: I32x2,
        edit: u32,
        mesh: Mesh,
    };

    // Инициализация машины состояний отрисовщика
    // ==========================================

    pub fn init(allocator: Allocator) !Renderer {

        // GUI RECT
        //=========

        const gui_rect_vertex = try Shader.init(allocator, shader_sources.rect_vertex, ShaderType.vertex);
        defer gui_rect_vertex.deinit();

        const gui_rect_fragment = try Shader.init(allocator, shader_sources.rect_fragment, ShaderType.fragment);
        defer gui_rect_fragment.deinit();

        const gui_rect_program = try ShaderProgram.init(
            allocator,
            &.{ gui_rect_vertex, gui_rect_fragment },
        );

        const gui_rect_mesh_vertices = [_]f32{
            0.0, 0.0, 0.0, 1.0,
            1.0, 0.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 0.0,
            1.0, 1.0, 1.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        };
        const gui_rect_mesh = Mesh.init(gui_rect_mesh_vertices[0..], &.{ 2, 2 });

        // GUI TEXT
        //=========

        const gui_text_vertex = try Shader.init(allocator, shader_sources.text_vertex, ShaderType.vertex);
        defer gui_text_vertex.deinit();

        const gui_text_fragment = try Shader.init(allocator, shader_sources.text_fragment, ShaderType.fragment);
        defer gui_text_fragment.deinit();

        const gui_text_program = try ShaderProgram.init(allocator, &[_]Shader{ gui_text_vertex, gui_text_fragment });

        var ft: c.FT_Library = undefined;
        if (c.FT_Init_FreeType(&ft) != 0) {
            std.debug.panic("[!FAILED!]:[FREETYPE]:Initialised", .{});
        }

        var face: c.FT_Face = undefined;
        if (c.FT_New_Face(ft, "data/fonts/main.ttf", 0, &face) != 0) {
            std.debug.panic("[!FAILED!]:[FREETYPE]:Open font", .{});
        }

        _ = c.FT_Set_Pixel_Sizes(face, 0, 24);

        const chars = [_]u16{ '#', '.', ',', '-', '|', '+', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'а', 'б', 'в', 'г', 'д', 'е', 'ё', 'ж', 'з', 'и', 'й', 'к', 'л', 'м', 'н', 'о', 'п', 'р', 'с', 'т', 'у', 'ф', 'х', 'ц', 'ч', 'ш', 'щ', 'ъ', 'ы', 'ь', 'э', 'ю', 'я' };
        var glyphs: [chars.len]Glyph = undefined;

        for (chars) |char, i| {
            if (c.FT_Load_Char(face, char, c.FT_LOAD_RENDER) != 0) {
                std.debug.panic("[!FAILED!]:[FREETYPE]:To load Glyph \"{}\"", .{char});
            }

            var texture: u32 = undefined;
            c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
            c.glGenTextures(1, &texture);
            c.glBindTexture(c.GL_TEXTURE_2D, texture);
            c.glTexImage2D(
                c.GL_TEXTURE_2D,
                0,
                c.GL_RED,
                @intCast(c_int, face.*.glyph.*.bitmap.width),
                @intCast(c_int, face.*.glyph.*.bitmap.rows),
                0,
                c.GL_RED,
                c.GL_UNSIGNED_BYTE,
                face.*.glyph.*.bitmap.buffer,
            );
            c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
            c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
            c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
            c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
            c.glBindTexture(c.GL_TEXTURE_2D, 0);

            glyphs[i] = Glyph{
                .texture = texture,
                .size = I32x2{
                    @intCast(i32, face.*.glyph.*.bitmap.width),
                    @intCast(i32, face.*.glyph.*.bitmap.rows),
                },
                .advance = @intCast(i32, face.*.glyph.*.advance.x) >> 6,
                .bearing = I32x2{
                    @intCast(i32, face.*.glyph.*.bitmap_left),
                    @intCast(i32, face.*.glyph.*.bitmap_top),
                },
            };
        }
        _ = c.FT_Done_Face(face);
        _ = c.FT_Done_FreeType(ft);

        // SHAPE QUAD
        //===========

        const shape_vertex = try Shader.init(allocator, shader_sources.shape_vertex, ShaderType.vertex);
        defer shape_vertex.deinit();

        const shape_fragment = try Shader.init(allocator, shader_sources.shape_fragment, ShaderType.fragment);
        defer shape_fragment.deinit();

        const shape_program = try ShaderProgram.init(allocator, &[_]Shader{ shape_vertex, shape_fragment });

        const shape_line_mesh_vertices = [_]f32{
            0.0, 0.0, 0.0, 0.0, 0.0, 1.0,
            1.0, 1.0, 1.0, 0.0, 0.0, 1.0,
        };

        var shape_line_mesh = Mesh.init(shape_line_mesh_vertices[0..], &.{ 3, 3 });
        shape_line_mesh.mode = Mesh.Mode.lines;

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

        const shape_quad_mesh = Mesh.init(shape_quad_mesh_vertices[0..], &.{ 3, 3 });

        return Renderer{
            .allocator = allocator,
            .gui = .{
                .rect = .{
                    .program = .{
                        .id = gui_rect_program,
                        .uniforms = .{
                            .rect = try gui_rect_program.getUniform("rect"),
                            .color = try gui_rect_program.getUniform("color"),
                            .vpsize = try gui_rect_program.getUniform("vpsize"),
                            .borders_width = try gui_rect_program.getUniform("borders_width"),
                            .borders_color = try gui_rect_program.getUniform("borders_color"),
                        },
                    },
                    .mesh = gui_rect_mesh,
                },
                .text = .{
                    .program = .{
                        .id = gui_text_program,
                        .uniforms = .{
                            .rect = try gui_text_program.getUniform("rect"),
                            .vpsize = try gui_text_program.getUniform("vpsize"),
                            .color = try gui_text_program.getUniform("color"),
                        },
                    },
                    .glyphs = glyphs,
                    .chars = chars,
                },
            },
            .shape = .{
                .program = .{
                    .id = shape_program,
                    .uniforms = .{
                        .model = try shape_program.getUniform("model"),
                        .view = try shape_program.getUniform("view"),
                        .proj = try shape_program.getUniform("proj"),
                        .color = try shape_program.getUniform("color"),
                        .light = .{
                            .color = try shape_program.getUniform("light.color"),
                            .direction = try shape_program.getUniform("light.direction"),
                            .diffuse = try shape_program.getUniform("light.diffuse"),
                            .ambient = try shape_program.getUniform("light.ambient"),
                            .specular = try shape_program.getUniform("light.specular"),
                        },
                    },
                },
                .line = .{
                    .mesh = shape_line_mesh,
                },
                .quad = .{
                    .mesh = shape_quad_mesh,
                },
            },
        };
    }

    // Уничтожение машины состояний отрисовщика
    // ========================================
    pub fn deinit(self: Renderer) void {
        self.gui.rect.program.id.deinit();
        self.gui.rect.mesh.deinit();
        self.gui.text.program.id.deinit();
        self.shape.program.id.deinit();
        self.shape.line.mesh.deinit();
        self.shape.quad.mesh.deinit();
        for (self.world.chunks) |chunk| {
            if (chunk != null) {
                chunk.?.mesh.deinit();
            }
        }
    }

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
                    for (self.gui.text.chars) |renderer_char, i| {
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
                                index |= @intCast(u8, @boolToInt(obj.grid[z][y][x] == world.Cell.block)) << 3;
                                index |= @intCast(u8, @boolToInt(obj.grid[z][y][x + 1] == world.Cell.block)) << 2;
                                index |= @intCast(u8, @boolToInt(obj.grid[z][y + 1][x + 1] == world.Cell.block)) << 1;
                                index |= @intCast(u8, @boolToInt(obj.grid[z][y + 1][x] == world.Cell.block)) << 0;
                                index |= @intCast(u8, @boolToInt(obj.grid[z + 1][y][x] == world.Cell.block)) << 7;
                                index |= @intCast(u8, @boolToInt(obj.grid[z + 1][y][x + 1] == world.Cell.block)) << 6;
                                index |= @intCast(u8, @boolToInt(obj.grid[z + 1][y + 1][x + 1] == world.Cell.block)) << 5;
                                index |= @intCast(u8, @boolToInt(obj.grid[z + 1][y + 1][x] == world.Cell.block)) << 4;
                            } else if (x == width - 1 and y < width - 1 and chunk_01 != null) {
                                index |= @intCast(u8, @boolToInt(obj.grid[z][y][x] == world.Cell.block)) << 3;
                                index |= @intCast(u8, @boolToInt(chunk_01.?.grid[z][y][0] == world.Cell.block)) << 2;
                                index |= @intCast(u8, @boolToInt(chunk_01.?.grid[z][y + 1][0] == world.Cell.block)) << 1;
                                index |= @intCast(u8, @boolToInt(obj.grid[z][y + 1][x] == world.Cell.block)) << 0;
                                index |= @intCast(u8, @boolToInt(obj.grid[z + 1][y][x] == world.Cell.block)) << 7;
                                index |= @intCast(u8, @boolToInt(chunk_01.?.grid[z + 1][y][0] == world.Cell.block)) << 6;
                                index |= @intCast(u8, @boolToInt(chunk_01.?.grid[z + 1][y + 1][0] == world.Cell.block)) << 5;
                                index |= @intCast(u8, @boolToInt(obj.grid[z + 1][y + 1][x] == world.Cell.block)) << 4;
                            } else if (x < width - 1 and y == width - 1 and chunk_10 != null) {
                                index |= @intCast(u8, @boolToInt(obj.grid[z][y][x] == world.Cell.block)) << 3;
                                index |= @intCast(u8, @boolToInt(obj.grid[z][y][x + 1] == world.Cell.block)) << 2;
                                index |= @intCast(u8, @boolToInt(chunk_10.?.grid[z][0][x + 1] == world.Cell.block)) << 1;
                                index |= @intCast(u8, @boolToInt(chunk_10.?.grid[z][0][x] == world.Cell.block)) << 0;
                                index |= @intCast(u8, @boolToInt(obj.grid[z + 1][y][x] == world.Cell.block)) << 7;
                                index |= @intCast(u8, @boolToInt(obj.grid[z + 1][y][x + 1] == world.Cell.block)) << 6;
                                index |= @intCast(u8, @boolToInt(chunk_10.?.grid[z + 1][0][x + 1] == world.Cell.block)) << 5;
                                index |= @intCast(u8, @boolToInt(chunk_10.?.grid[z + 1][0][x] == world.Cell.block)) << 4;
                            } else if (chunk_01 != null and chunk_10 != null and chunk_11 != null) {
                                index |= @intCast(u8, @boolToInt(obj.grid[z][y][x] == world.Cell.block)) << 3;
                                index |= @intCast(u8, @boolToInt(chunk_01.?.grid[z][y][0] == world.Cell.block)) << 2;
                                index |= @intCast(u8, @boolToInt(chunk_11.?.grid[z][0][0] == world.Cell.block)) << 1;
                                index |= @intCast(u8, @boolToInt(chunk_10.?.grid[z][0][x] == world.Cell.block)) << 0;
                                index |= @intCast(u8, @boolToInt(obj.grid[z + 1][y][x] == world.Cell.block)) << 7;
                                index |= @intCast(u8, @boolToInt(chunk_01.?.grid[z + 1][y][0] == world.Cell.block)) << 6;
                                index |= @intCast(u8, @boolToInt(chunk_11.?.grid[z + 1][0][0] == world.Cell.block)) << 5;
                                index |= @intCast(u8, @boolToInt(chunk_10.?.grid[z + 1][0][x] == world.Cell.block)) << 4;
                            }

                            if (index == 0 or index == 255) continue;

                            var i: usize = 0;
                            while (mct.tri[index][i] < 12) : (i += 3) {
                                const p1 = mct.edge[mct.tri[index][i + 0]];
                                const p2 = mct.edge[mct.tri[index][i + 1]];
                                const p3 = mct.edge[mct.tri[index][i + 2]];
                                const n = linmath.normalize(linmath.cross(p2 - p1, p3 - p1));

                                S.vertices[(vertcnt + 0) * vertsize + 0] = p1[0] + @intToFloat(f32, x) + @intToFloat(f32, obj.pos[0] * width);
                                S.vertices[(vertcnt + 0) * vertsize + 1] = p1[1] + @intToFloat(f32, y) + @intToFloat(f32, obj.pos[1] * width);
                                S.vertices[(vertcnt + 0) * vertsize + 2] = p1[2] + @intToFloat(f32, z);
                                S.vertices[(vertcnt + 0) * vertsize + 3] = n[0];
                                S.vertices[(vertcnt + 0) * vertsize + 4] = n[1];
                                S.vertices[(vertcnt + 0) * vertsize + 5] = n[2];

                                S.vertices[(vertcnt + 1) * vertsize + 0] = p2[0] + @intToFloat(f32, x) + @intToFloat(f32, obj.pos[0] * width);
                                S.vertices[(vertcnt + 1) * vertsize + 1] = p2[1] + @intToFloat(f32, y) + @intToFloat(f32, obj.pos[1] * width);
                                S.vertices[(vertcnt + 1) * vertsize + 2] = p2[2] + @intToFloat(f32, z);
                                S.vertices[(vertcnt + 1) * vertsize + 3] = n[0];
                                S.vertices[(vertcnt + 1) * vertsize + 4] = n[1];
                                S.vertices[(vertcnt + 1) * vertsize + 5] = n[2];

                                S.vertices[(vertcnt + 2) * vertsize + 0] = p3[0] + @intToFloat(f32, x) + @intToFloat(f32, obj.pos[0] * width);
                                S.vertices[(vertcnt + 2) * vertsize + 1] = p3[1] + @intToFloat(f32, y) + @intToFloat(f32, obj.pos[1] * width);
                                S.vertices[(vertcnt + 2) * vertsize + 2] = p3[2] + @intToFloat(f32, z);
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
};
