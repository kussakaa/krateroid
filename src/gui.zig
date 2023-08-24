const std = @import("std");

const Mesh = @import("mesh.zig").Mesh;
const glsl = @import("glsl.zig");
const shader_sources = @import("shader_sources.zig");

pub const Color = @Vector(4, f32);
// Point {X|Y}
pub const Point = @Vector(2, i32);
// Rect {min X|min Y|max X|max Y}
pub const Rect = @Vector(4, i32);

pub const ComponentTag = enum {
    panel_color,
    panel_border,
    text,
};

pub const Component = union(ComponentTag) {
    panel_color: struct {
        rect: Rect,
        color: Color = .{ 0.0, 0.0, 0.0, 1.0 },
    },
    panel_border: struct {
        rect: Rect,
        color: Color = .{ 0.0, 0.0, 0.0, 1.0 },
        width: i32 = 3,
    },
    text: struct {
        text: []const u16,
        color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
    },
};

pub const Control = std.ArrayList(Component);
pub const Controls = std.ArrayList(?Control);

pub const RenderSystem = struct {
    allocator: std.mem.Allocator,
    vpsize: Point = .{ 1200, 900 },
    rect_mesh: Mesh,
    panel_color_program: glsl.Program,
    panel_border_program: glsl.Program,

    pub fn init(allocator: std.mem.Allocator) !RenderSystem {
        const rect_mesh_vertices = [_]f32{
            0.0, 0.0, 0.0, 1.0,
            1.0, 0.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 0.0,
            1.0, 1.0, 1.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        };
        const rect_mesh = Mesh.init(rect_mesh_vertices[0..], &.{ 2, 2 });

        const panel_color_vertex = try glsl.Shader.initFormFile(
            allocator,
            "data/shader/gui/panel/color/vertex.glsl",
            glsl.ShaderType.vertex,
        );
        defer panel_color_vertex.deinit();

        const panel_color_fragment = try glsl.Shader.initFormFile(
            allocator,
            "data/shader/gui/panel/color/fragment.glsl",
            glsl.ShaderType.fragment,
        );
        defer panel_color_fragment.deinit();

        var panel_color_program = try glsl.Program.init(
            allocator,
            &.{ panel_color_vertex, panel_color_fragment },
        );

        try panel_color_program.addUniform("rect");
        try panel_color_program.addUniform("vpsize");
        try panel_color_program.addUniform("color");

        const panel_border_vertex = try glsl.Shader.initFormFile(
            allocator,
            "data/shader/gui/panel/border/vertex.glsl",
            glsl.ShaderType.vertex,
        );
        defer panel_border_vertex.deinit();

        const panel_border_fragment = try glsl.Shader.initFormFile(
            allocator,
            "data/shader/gui/panel/border/fragment.glsl",
            glsl.ShaderType.fragment,
        );
        defer panel_border_fragment.deinit();

        var panel_border_program = try glsl.Program.init(
            allocator,
            &.{ panel_border_vertex, panel_border_fragment },
        );

        try panel_border_program.addUniform("rect");
        try panel_border_program.addUniform("vpsize");
        try panel_border_program.addUniform("color");
        try panel_border_program.addUniform("width");

        return RenderSystem{
            .allocator = allocator,
            .rect_mesh = rect_mesh,
            .panel_color_program = panel_color_program,
            .panel_border_program = panel_border_program,
        };
    }

    pub fn deinit(self: *RenderSystem) void {
        self.rect_mesh.deinit();
        self.panel_color_program.deinit();
        self.panel_border_program.deinit();
    }

    pub fn draw(self: RenderSystem, controls: Controls) void {
        for (controls.items) |control| {
            if (control != null) {
                for (control.?.items) |component| {
                    switch (component) {
                        Component.panel_color => |panel| {
                            self.panel_color_program.use();
                            self.panel_color_program.setUniform(0, panel.rect);
                            self.panel_color_program.setUniform(1, self.vpsize);
                            self.panel_color_program.setUniform(2, panel.color);
                            self.rect_mesh.draw();
                        },
                        Component.panel_border => |panel| {
                            self.panel_border_program.use();
                            self.panel_border_program.setUniform(0, panel.rect);
                            self.panel_border_program.setUniform(1, self.vpsize);
                            self.panel_border_program.setUniform(2, panel.color);
                            self.panel_border_program.setUniform(3, panel.width);
                            self.rect_mesh.draw();
                        },
                        Component.text => {},
                    }
                }
            }
        }
    }
};

pub const InputSystem = struct {};
