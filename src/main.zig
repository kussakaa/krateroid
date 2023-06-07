const c = @import("c.zig");
const std = @import("std");
const panic = std.debug.panic;
const linmath = @import("linmath.zig");
const Vec4 = linmath.Vec4;
const Mat4 = linmath.Mat4;
const glfw = @import("glfw.zig");
const mesh = @import("mesh.zig");
const shader = @import("shader.zig");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();
    const window = try glfw.Window.create(800, 600, "krateroid");
    defer window.destroy();

    const rect_mesh_vertices = [_]f32{
        -0.5, -0.5, 1.0, 0.0, 0.0,
        0.5,  -0.5, 0.0, 1.0, 0.0,
        0.5,  0.5,  0.0, 0.0, 1.0,
        0.5,  0.5,  0.0, 0.0, 1.0,
        -0.5, 0.5,  1.0, 1.0, 1.0,
        -0.5, -0.5, 1.0, 0.0, 0.0,
    };
    const rect_mesh = mesh.Mesh.create(rect_mesh_vertices[0..], &[_]u32{ 2, 3 });
    defer rect_mesh.delete();

    const shader_vertex = try shader.Shader.create(std.heap.page_allocator, shader_sources.main_vertex, shader.ShaderType.vertex);
    const shader_fragment = try shader.Shader.create(std.heap.page_allocator, shader_sources.main_fragment, shader.ShaderType.fragment);
    const program = try shader.ShaderProgram.create(std.heap.page_allocator, &[_]shader.Shader{ shader_vertex, shader_fragment });
    defer program.delete();
    shader_vertex.delete();
    shader_fragment.delete();
    program.use();
    const uniform_color = program.getUniform("color");
    const uniform_model = program.getUniform("model");
    const uniform_view = program.getUniform("view");
    const uniform_proj = program.getUniform("proj");
    var angle: f32 = 0.0;
    var model = linmath.rotz(angle);
    const view = linmath.Mat4identity;
    var proj = linmath.Mat4identity;

    var run = true;
    while (run) {
        run = !window.shouldClose();
        if (glfw.isJustPressed(256)) run = false;
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glClearColor(0.1, 0.1, 0.1, 1.0);
        const window_size = window.getSize();
        const window_ratio = @intToFloat(f32, window_size.x) / @intToFloat(f32, window_size.y);
        proj[0][0] = 1.0 / window_ratio;
        angle += 0.001;
        model = linmath.rotz(angle);
        shader.ShaderProgram.setUniform(Vec4, uniform_color, Vec4{ 0.6, 0.59, 0.1, 1.0 });
        shader.ShaderProgram.setUniform(Mat4, uniform_model, model);
        shader.ShaderProgram.setUniform(Mat4, uniform_view, view);
        shader.ShaderProgram.setUniform(Mat4, uniform_proj, proj);
        rect_mesh.draw();
        window.swapBuffers();
        glfw.pollEvents();
    }
}
