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

    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_CULL_FACE);
    c.glCullFace(c.GL_FRONT);
    c.glFrontFace(c.GL_CW);
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    c.glClearColor(0.113, 0.125, 0.129, 1.0);

    var renderer = try Renderer.init();
    defer renderer.destroy();

    var last_time = @floatCast(f32, c.glfwGetTime());

    var run = true;
    while (run) {
        run = !window.shouldClose();
        if (glfw.isJustPressed(256)) run = false;

        const window_size = window.getSize();
        const vpsize = linmath.I32x2{ window_size.x, window_size.y };
        renderer.vpsize = vpsize;
        const current_time = @floatCast(f32, c.glfwGetTime());
        const dt = current_time - last_time;
        last_time = current_time;
        _ = dt;

        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glClearColor(0.113, 0.125, 0.129, 1.0);
        c.glEnable(c.GL_DEPTH_TEST);
        // 3D

        c.glDisable(c.GL_DEPTH_TEST);
        // 2D
        renderer.color = Vec{ 0.596, 0.592, 0.101, 1.0 };
        renderer.gui.rect.alignment = gui.Alignment.left_bottom;
        renderer.draw(gui.Rect{ 20, 20, 180, 80 });

        renderer.color = Vec{ 0.596, 0.592, 0.101, 1.0 };
        renderer.gui.rect.alignment = gui.Alignment.left_top;
        renderer.draw(gui.Rect{ 20, 20, 180, 80 });

        renderer.color = Vec{ 0.596, 0.592, 0.101, 1.0 };
        renderer.gui.rect.alignment = gui.Alignment.right_bottom;
        renderer.draw(gui.Rect{ 20, 20, 180, 80 });

        renderer.color = Vec{ 0.596, 0.592, 0.101, 1.0 };
        renderer.gui.rect.alignment = gui.Alignment.right_top;
        renderer.draw(gui.Rect{ 20, 20, 180, 80 });

        renderer.color = Vec{ 0.843, 0.6, 0.129, 1.0 };
        renderer.gui.rect.alignment = gui.Alignment.center_bottom;
        renderer.draw(gui.Rect{ -30, 20, 30, 50 });

        renderer.color = Vec{ 0.843, 0.6, 0.129, 1.0 };
        renderer.gui.rect.alignment = gui.Alignment.right_center;
        renderer.draw(gui.Rect{ 20, -30, 50, 30 });

        renderer.color = Vec{ 0.843, 0.6, 0.129, 1.0 };
        renderer.gui.rect.alignment = gui.Alignment.center_top;
        renderer.draw(gui.Rect{ -30, 20, 30, 50 });

        renderer.color = Vec{ 0.843, 0.6, 0.129, 1.0 };
        renderer.gui.rect.alignment = gui.Alignment.left_center;
        renderer.draw(gui.Rect{ 20, -30, 50, 30 });

        renderer.color = Vec{ 0.8, 0.141, 0.113, 1.0 };
        renderer.gui.rect.alignment = gui.Alignment.center_center;
        renderer.draw(gui.Rect{ -20, -20, 20, 20 });

        window.swapBuffers();
        glfw.pollEvents();
    }
}
