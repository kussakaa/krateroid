const std = @import("std");
const c = @import("c.zig");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");
const shape = @import("shape.zig");
const world = @import("world.zig");
const mct = @import("mct.zig");
const Shader = @import("shader.zig").Shader;
const ShaderType = @import("shader.zig").ShaderType;
const ShaderProgram = @import("shader.zig").ShaderProgram;
const Mesh = @import("mesh.zig").Mesh;
const Camera = @import("camera.zig").Camera;

const linmath = @import("linmath.zig");
const Color = linmath.F32x4;
const Vec4 = linmath.F32x4;
const Vec3 = linmath.F32x3;
const I32x4 = linmath.I32x4;
const I32x2 = linmath.I32x2;
const Mat = linmath.Mat;
const MatIdentity = linmath.MatIdentity;

pub const Renderer = struct {
    vpsize: I32x2 = .{ 800, 600 },
    color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
    camera: Camera = .{},
    light: struct {
        direction: Vec3 = .{ 0.2, 0.3, 1.0 },
        intensity: f32 = 0.5,
        ambient: f32 = 0.3,
    },
    gui: struct {
        rect: struct {
            color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
            alignment: gui.Alignment = gui.Alignment.left_bottom,
            border: struct {
                width: i32 = 1,
                color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
            },
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
            color: Color = .{ 0.7, 0.7, 0.7, 1.0 },
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
        program: struct {
            id: ShaderProgram,
            uniforms: struct {
                model: i32,
                view: i32,
                proj: i32,
                light_direction: i32,
                light_intensity: i32,
                light_ambient: i32,
            },
        },
        quad: struct {
            mesh: Mesh,
        },
    },
    world: struct {
        chunks: [16]?Mesh = [1]?Mesh{null} ** 16,
    },

    const Glyph = struct {
        texture: u32,
        size: I32x2,
        advance: i32,
        bearing: I32x2,
    };

    pub fn init() !Renderer {

        //=============
        // GUI RECT
        //=============

        const gui_rect_vertex = try Shader.init(
            std.heap.page_allocator,
            shader_sources.rect_vertex,
            ShaderType.vertex,
        );
        defer gui_rect_vertex.destroy();

        const gui_rect_fragment = try Shader.init(
            std.heap.page_allocator,
            shader_sources.rect_fragment,
            ShaderType.fragment,
        );
        defer gui_rect_fragment.destroy();

        const gui_rect_program = try ShaderProgram.init(
            std.heap.page_allocator,
            &[_]Shader{ gui_rect_vertex, gui_rect_fragment },
        );

        const gui_rect_mesh_vertices = [_]f32{
            0.0, 0.0, 0.0, 1.0,
            1.0, 0.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 0.0,
            1.0, 1.0, 1.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        };
        const gui_rect_mesh = Mesh.init(gui_rect_mesh_vertices[0..], &[_]u32{ 2, 2 });

        //=============
        // GUI TEXT
        //=============

        const gui_text_vertex = try Shader.init(
            std.heap.page_allocator,
            shader_sources.text_vertex,
            ShaderType.vertex,
        );
        defer gui_text_vertex.destroy();

        const gui_text_fragment = try Shader.init(
            std.heap.page_allocator,
            shader_sources.text_fragment,
            ShaderType.fragment,
        );
        defer gui_text_fragment.destroy();

        const gui_text_program = try ShaderProgram.init(
            std.heap.page_allocator,
            &[_]Shader{ gui_text_vertex, gui_text_fragment },
        );

        var ft: c.FT_Library = undefined;
        if (c.FT_Init_FreeType(&ft) != 0) {
            std.debug.panic("[!!!ERROR!!!]:[FT]:Initialised", .{});
        }

        var face: c.FT_Face = undefined;
        if (c.FT_New_Face(ft, "data/fonts/JetBrainsMono-Bold.ttf", 0, &face) != 0) {
            std.debug.panic("[!!!ERROR!!!]:[FT]:Open font", .{});
        }

        _ = c.FT_Set_Pixel_Sizes(face, 0, 24);

        const chars = [_]u16{ '#', '.', ',', '-', '|', '+', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'а', 'б', 'в', 'г', 'д', 'е', 'ё', 'ж', 'з', 'и', 'й', 'к', 'л', 'м', 'н', 'о', 'п', 'р', 'с', 'т', 'у', 'ф', 'х', 'ц', 'ч', 'ш', 'щ', 'ъ', 'ы', 'ь', 'э', 'ю', 'я' };
        var glyphs: [chars.len]Glyph = undefined;

        for (chars) |char, i| {
            if (c.FT_Load_Char(face, char, c.FT_LOAD_RENDER) != 0) {
                std.debug.panic("[!!!ERROR!!!]:[FT]:To load Glyph \"{}\"", .{char});
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

        //=================
        // SHAPE QUAD
        //=================

        const shape_vertex = try Shader.init(
            std.heap.page_allocator,
            shader_sources.shape_vertex,
            ShaderType.vertex,
        );
        defer shape_vertex.destroy();

        const shape_fragment = try Shader.init(
            std.heap.page_allocator,
            shader_sources.shape_fragment,
            ShaderType.fragment,
        );
        defer shape_fragment.destroy();

        const shape_program = try ShaderProgram.init(
            std.heap.page_allocator,
            &[_]Shader{ shape_vertex, shape_fragment },
        );

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

        const shape_quad_mesh = Mesh.init(shape_quad_mesh_vertices[0..], &[_]u32{ 3, 3 });

        return Renderer{
            .light = .{},
            .gui = .{
                .rect = .{
                    .border = .{},
                    .program = .{
                        .id = gui_rect_program,
                        .uniforms = .{
                            .rect = gui_rect_program.getUniform("rect"),
                            .color = gui_rect_program.getUniform("color"),
                            .vpsize = gui_rect_program.getUniform("vpsize"),
                            .borders_width = gui_rect_program.getUniform("borders_width"),
                            .borders_color = gui_rect_program.getUniform("borders_color"),
                        },
                    },
                    .mesh = gui_rect_mesh,
                },
                .text = .{
                    .program = .{
                        .id = gui_text_program,
                        .uniforms = .{
                            .rect = gui_text_program.getUniform("rect"),
                            .vpsize = gui_text_program.getUniform("vpsize"),
                            .color = gui_text_program.getUniform("color"),
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
                        .model = shape_program.getUniform("model"),
                        .view = shape_program.getUniform("view"),
                        .proj = shape_program.getUniform("proj"),
                        .light_direction = shape_program.getUniform("light_direction"),
                        .light_intensity = shape_program.getUniform("light_intensity"),
                        .light_ambient = shape_program.getUniform("light_ambient"),
                    },
                },
                .quad = .{
                    .mesh = shape_quad_mesh,
                },
            },
            .world = .{},
        };
    }

    pub fn destroy(self: Renderer) void {
        self.gui.rect.program.id.destroy();
        self.gui.rect.mesh.destroy();
        self.gui.text.program.id.destroy();
        self.shape.program.id.destroy();
        self.shape.quad.mesh.destroy();
    }

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
            shape.Quad => {
                self.shape.program.id.use();
                const model = linmath.mul(linmath.Scale(obj.size), linmath.Pos(obj.pos));
                ShaderProgram.setUniform(self.shape.program.uniforms.model, model);
                ShaderProgram.setUniform(self.shape.program.uniforms.view, self.camera.view);
                ShaderProgram.setUniform(self.shape.program.uniforms.proj, self.camera.proj);
                ShaderProgram.setUniform(self.shape.program.uniforms.light_direction, self.light.direction);
                ShaderProgram.setUniform(self.shape.program.uniforms.light_intensity, self.light.intensity);
                ShaderProgram.setUniform(self.shape.program.uniforms.light_ambient, self.light.ambient);
                self.shape.quad.mesh.draw();
            },
            world.Chunk => {},
            else => std.debug.panic("[!FAILED!]:[RENDERER]:Impossible to draw an object of this type!"),
        }
    }
};
