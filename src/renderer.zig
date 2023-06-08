const std = @import("std");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");
const Shader = @import("shader.zig").Shader;
const ShaderType = @import("shader.zig").ShaderType;
const ShaderProgram = @import("shader.zig").ShaderProgram;

pub const Renderer = struct {
    gui: struct {
        rect: struct {
            shader: ShaderProgram,
        },
    },

    pub fn init() !Renderer {
        const gui_rect_vertex = try Shader.init(std.heap.page_allocator, shader_sources.main_vertex, ShaderType.vertex);
        const gui_rect_fragment = try Shader.init(std.heap.page_allocator, shader_sources.main_fragment, ShaderType.fragment);
        const gui_rect_shader = try ShaderProgram.init(std.heap.page_allocator, &[_]Shader{ gui_rect_vertex, gui_rect_fragment });
        return Renderer{
            .gui = .{
                .rect = .{
                    .shader = gui_rect_shader,
                },
            },
        };
    }

    pub fn destroy(self: Renderer) void {
        _ = self;
    }
};
