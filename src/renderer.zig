const std = @import("std");
const c = @import("c.zig");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");
const Shader = @import("shader.zig").Shader;
const ShaderType = @import("shader.zig").ShaderType;
const ShaderProgram = @import("shader.zig").ShaderProgram;
const Mesh = @import("mesh.zig").Mesh;

const Color = @import("linmath.zig").F32x4;
const I32x4 = @import("linmath.zig").I32x4;
const I32x2 = @import("linmath.zig").I32x2;

pub const Renderer = struct {
    vpsize: I32x2 = I32x2{ 1200, 900 },
    color: Color = Color{ 1.0, 1.0, 1.0, 1.0 },
    gui: struct {
        rect: struct {
            color: Color = Color{ 1.0, 1.0, 1.0, 1.0 },
            alignment: gui.Alignment = gui.Alignment.left_top,
            borders: struct {
                width: i32 = 0,
                color: Color = Color{ 1.0, 1.0, 1.0, 1.0 },
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
            color: Color = Color{ 0.921, 0.858, 0.698, 1.0 },
            program: struct {
                id: ShaderProgram,
                uniforms: struct {
                    rect: i32,
                    vpsize: i32,
                    color: i32,
                },
            },
            chars: [72]u16,
            glyphs: [72]Glyph,
        },
    },

    const Glyph = struct {
        texture: u32,
        size: I32x2,
        advance: i32,
        bearing: I32x2,
    };

    pub fn init() !Renderer {
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

        const gui_rect_mesh_vertices = [_]f32{
            0.0, 0.0, 0.0, 1.0,
            1.0, 0.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 0.0,
            1.0, 1.0, 1.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        };
        const gui_rect_mesh = Mesh.init(gui_rect_mesh_vertices[0..], &[_]u32{ 2, 2 });

        var ft: c.FT_Library = undefined;
        if (c.FT_Init_FreeType(&ft) != 0) {
            std.debug.panic("[!!!ERROR!!!]:[FT]:Initialised", .{});
        }

        var face: c.FT_Face = undefined;
        if (c.FT_New_Face(ft, "data/fonts/JetBrainsMono-Bold.ttf", 0, &face) != 0) {
            std.debug.panic("[!!!ERROR!!!]:[FT]:Open font", .{});
        }

        _ = c.FT_Set_Pixel_Sizes(face, 0, 24);

        const chars = [_]u16{ '#', '.', ',', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'а', 'б', 'в', 'г', 'д', 'е', 'ё', 'ж', 'з', 'и', 'й', 'к', 'л', 'м', 'н', 'о', 'п', 'р', 'с', 'т', 'у', 'ф', 'х', 'ц', 'ч', 'ш', 'щ', 'ъ', 'ы', 'ь', 'э', 'ю', 'я' };
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

        return Renderer{
            .gui = .{
                .rect = .{
                    .borders = .{},
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
        };
    }

    pub fn draw(self: *Renderer, obj: anytype) void {
        switch (@TypeOf(obj)) {
            gui.Rect => {
                self.gui.rect.program.id.use();
                ShaderProgram.setUniform(
                    I32x4,
                    self.gui.rect.program.uniforms.rect,
                    gui.rectAlignOfVp(
                        obj,
                        self.gui.rect.alignment,
                        self.vpsize,
                    ),
                );
                ShaderProgram.setUniform(
                    I32x2,
                    self.gui.rect.program.uniforms.vpsize,
                    self.vpsize,
                );
                ShaderProgram.setUniform(
                    Color,
                    self.gui.rect.program.uniforms.color,
                    self.gui.rect.color,
                );
                ShaderProgram.setUniform(
                    i32,
                    self.gui.rect.program.uniforms.borders_width,
                    self.gui.rect.borders.width,
                );
                ShaderProgram.setUniform(
                    Color,
                    self.gui.rect.program.uniforms.borders_color,
                    self.gui.rect.borders.color,
                );
                self.gui.rect.mesh.draw();
            },
            gui.Text => {
                var advance: i32 = 0;
                self.gui.text.program.id.use();
                glyph: for (obj.data) |char| {
                    if (char == ' ') {
                        advance += 10;
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
                            ShaderProgram.setUniform(I32x4, self.gui.text.program.uniforms.rect, gui.Rect{
                                min[0] + advance + self.gui.text.glyphs[i].bearing[0],
                                min[1] - (max[1] - min[1] - self.gui.text.glyphs[i].bearing[1]),
                                max[0] + advance + self.gui.text.glyphs[i].bearing[0],
                                max[1] - (max[1] - min[1] - self.gui.text.glyphs[i].bearing[1]),
                            });
                            ShaderProgram.setUniform(I32x2, self.gui.text.program.uniforms.vpsize, self.vpsize);
                            ShaderProgram.setUniform(Color, self.gui.text.program.uniforms.color, self.gui.text.color);
                            self.gui.rect.mesh.draw();
                            advance += self.gui.text.glyphs[i].advance;
                            continue :glyph;
                        }
                    }
                }
            },
            gui.Button => {
                self.gui.rect.color = Color{ 0.400, 0.360, 0.329, 1.0 };
                self.gui.rect.borders.width = 5;
                switch (obj.state) {
                    gui.Button.State.Normal => self.gui.rect.borders.color = Color{ 0.235, 0.219, 0.211, 1.0 },
                    gui.Button.State.Focused => self.gui.rect.borders.color = Color{ 0.484, 0.435, 0.392, 1.0 },
                    gui.Button.State.Pushed => self.gui.rect.borders.color = Color{ 0.658, 0.6, 0.517, 1.0 },
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
            else => std.debug.panic("[!!!ERROR!!!]:[RENDERER]:Impossible to draw an object of this type!"),
        }
    }

    pub fn destroy(self: Renderer) void {
        self.gui.rect.program.id.destroy();
        self.gui.rect.mesh.destroy();
        self.gui.text.program.id.destroy();
    }
};
