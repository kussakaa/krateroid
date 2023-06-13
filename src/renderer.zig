const std = @import("std");
const c = @import("c.zig");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");
const Shader = @import("shader.zig").Shader;
const ShaderType = @import("shader.zig").ShaderType;
const ShaderProgram = @import("shader.zig").ShaderProgram;
const Mesh = @import("mesh.zig").Mesh;

const linmath = @import("linmath.zig");
const Color = linmath.F32x4;
const I32x4 = linmath.I32x4;
const I32x2 = linmath.I32x2;

pub const Renderer = struct {
    vpsize: linmath.I32x2,
    color: Color,
    gui: struct {
        rect: struct {
            alignment: gui.Alignment,
            shader: struct {
                id: ShaderProgram,
                uniforms: struct {
                    rect: i32,
                    color: i32,
                    vpsize: i32,
                },
            },
            mesh: Mesh,
        },
        //font: struct {},
    },

    pub fn init() !Renderer {
        const gui_rect_vertex = try Shader.init(std.heap.page_allocator, shader_sources.rect_vertex, ShaderType.vertex);
        const gui_rect_fragment = try Shader.init(std.heap.page_allocator, shader_sources.rect_fragment, ShaderType.fragment);
        const gui_rect_shader = try ShaderProgram.init(std.heap.page_allocator, &[_]Shader{ gui_rect_vertex, gui_rect_fragment });

        gui_rect_vertex.destroy();
        gui_rect_fragment.destroy();

        const gui_rect_mesh_vertices = [_]f32{
            0.0, 0.0,
            1.0, 0.0,
            1.0, 1.0,
            1.0, 1.0,
            0.0, 1.0,
            0.0, 0.0,
        };
        const gui_rect_mesh = Mesh.init(gui_rect_mesh_vertices[0..], &[_]u32{2});

        return Renderer{
            .vpsize = linmath.I32x2{ 800, 800 },
            .color = Color{ 1.0, 1.0, 1.0, 1.0 },
            .gui = .{
                .rect = .{
                    .alignment = gui.Alignment.left_top,
                    .shader = .{
                        .id = gui_rect_shader,
                        .uniforms = .{
                            .rect = gui_rect_shader.getUniform("rect"),
                            .color = gui_rect_shader.getUniform("color"),
                            .vpsize = gui_rect_shader.getUniform("vpsize"),
                        },
                    },
                    .mesh = gui_rect_mesh,
                },
            },
        };
    }

    pub fn draw(self: *Renderer, obj: anytype) void {
        switch (@TypeOf(obj)) {
            gui.Rect => {
                self.gui.rect.shader.id.use();
                ShaderProgram.setUniform(I32x4, self.gui.rect.shader.uniforms.rect, gui.rectAlignOfVp(obj, self.gui.rect.alignment, self.vpsize));
                ShaderProgram.setUniform(I32x2, self.gui.rect.shader.uniforms.vpsize, self.vpsize);
                ShaderProgram.setUniform(Color, self.gui.rect.shader.uniforms.color, self.color);
                self.gui.rect.mesh.draw();
            },
            gui.Button => {
                switch (obj.state) {
                    gui.Button.State.Disabled => self.color = Color{ 0.113, 0.125, 0.129, 1.0 },
                    gui.Button.State.Focused => self.color = Color{ 0.235, 0.219, 0.211, 1.0 },
                    gui.Button.State.Pushed, gui.Button.State.Unpushed => self.color = Color{ 0.400, 0.360, 0.329, 1.0 },
                }
                const alignment = self.gui.rect.alignment;
                self.gui.rect.alignment = obj.alignment;
                self.draw(obj.rect);
                self.gui.rect.alignment = alignment;
            },
            gui.Gui => {
                for (obj.buttons.items) |button| {
                    self.draw(button);
                }
            },
            else => std.debug.panic("[RENDERER]:[ERROR]:Impossible to draw an object of this type!"),
        }
    }

    pub fn destroy(self: Renderer) void {
        self.gui.rect.shader.id.destroy();
        self.gui.rect.mesh.destroy();
    }
};
