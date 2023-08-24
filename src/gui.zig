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
    color_panel,
    border_panel,
    text,
};

pub const Component = union(ComponentTag) {
    color_panel: struct {
        rect: Rect,
        color: Color = .{ 0.0, 0.0, 0.0, 1.0 },
    },
    border_panel: struct {
        rect: Rect,
        color: Color = .{ 0.0, 0.0, 0.0, 1.0 },
        width: u32,
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
    color_panel_program: glsl.Program,

    pub fn init(allocator: std.mem.Allocator) !RenderSystem {
        const color_panel_vertex = try glsl.Shader.initFormFile(
            allocator,
            "data/shader/color_panel_vertex.glsl",
            glsl.ShaderType.vertex,
        );
        defer color_panel_vertex.deinit();

        const color_panel_fragment = try glsl.Shader.initFormFile(
            allocator,
            "data/shader/color_panel_fragment.glsl",
            glsl.ShaderType.fragment,
        );
        defer color_panel_fragment.deinit();

        var color_panel_program = try glsl.Program.init(
            allocator,
            &.{ color_panel_vertex, color_panel_fragment },
        );

        try color_panel_program.addUniform("rect");
        try color_panel_program.addUniform("vpsize");
        try color_panel_program.addUniform("color");

        const rect_mesh_vertices = [_]f32{
            0.0, 0.0, 0.0, 1.0,
            1.0, 0.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 0.0,
            1.0, 1.0, 1.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        };
        const rect_mesh = Mesh.init(rect_mesh_vertices[0..], &.{ 2, 2 });

        return RenderSystem{
            .allocator = allocator,
            .rect_mesh = rect_mesh,
            .color_panel_program = color_panel_program,
        };
    }

    pub fn deinit(self: *RenderSystem) void {
        self.rect_mesh.deinit();
        self.color_panel_program.deinit();
    }

    pub fn draw(self: RenderSystem, controls: Controls) void {
        for (controls.items) |control| {
            if (control != null) {
                for (control.?.items) |component| {
                    switch (component) {
                        Component.color_panel => |rect| {
                            self.color_panel_program.use();
                            self.color_panel_program.setUniform(0, rect.rect);
                            self.color_panel_program.setUniform(1, self.vpsize);
                            self.color_panel_program.setUniform(2, rect.color);
                            self.rect_mesh.draw();
                        },
                        Component.border_panel => {},
                        Component.text => {},
                    }
                }
            }
        }
    }
};

pub const InputSystem = struct {};
