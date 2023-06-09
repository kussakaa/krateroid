const c = @import("c.zig");
const std = @import("std");
const linmath = @import("linmath.zig");
const Vec = linmath.Vec;
const Mat = linmath.Mat;
const glfw = @import("glfw.zig");
const mesh = @import("mesh.zig");
const shader = @import("shader.zig");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");
const Renderer = @import("renderer.zig").Renderer;

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();
    const window = try glfw.Window.create(800, 600, "krateroid");
    defer window.destroy();

    var renderer = try Renderer.init();
    defer renderer.destroy();

    var last_time = @floatCast(f32, c.glfwGetTime());

    var run = true;
    while (run) {
        run = !window.shouldClose();
        if (glfw.isJustPressed(256)) run = false;

        const window_size = window.getSize();
        const viewport = linmath.I32x4{ 0, 0, window_size.x, window_size.y };
        renderer.viewport = viewport;
        const current_time = @floatCast(f32, c.glfwGetTime());
        const dt = current_time - last_time;
        last_time = current_time;
        _ = dt;

        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glClearColor(0.113, 0.125, 0.129, 1.0);

        renderer.color = Vec{ 0.596, 0.592, 0.101, 1.0 };
        renderer.draw(gui.Rect.init(gui.Point.init(20, 20), gui.Point.init(200, 100)));
        renderer.color = Vec{ 0.843, 0.6, 0.129, 1.0 };
        renderer.draw(gui.Rect.init(gui.Point.init(20, 140), gui.Point.init(200, 100)));
        window.swapBuffers();
        glfw.pollEvents();
    }
}
