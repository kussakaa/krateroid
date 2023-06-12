const c = @import("c.zig");
const std = @import("std");
const linmath = @import("linmath.zig");
const Vec = linmath.Vec;
const Color = linmath.F32x4;
const Mat = linmath.Mat;
const glfw = @import("glfw.zig");
const mesh = @import("mesh.zig");
const shader = @import("shader.zig");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");
const Renderer = @import("renderer.zig").Renderer;
const Event = @import("events.zig").Event;

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
    c.glClearColor(0.0, 0.0, 0.0, 1.0);

    var renderer = try Renderer.init();
    defer renderer.destroy();

    var gui_state = gui.Gui.init();
    try gui_state.addButton(gui.Button{
        .rect = gui.Rect{ -80, 40, 80, 100 },
        .state = gui.Button.State.Disabled,
        .alignment = gui.Alignment.center_center,
    });
    try gui_state.addButton(gui.Button{
        .rect = gui.Rect{ -80, -30, 80, 30 },
        .state = gui.Button.State.Disabled,
        .alignment = gui.Alignment.center_center,
    });
    try gui_state.addButton(gui.Button{
        .rect = gui.Rect{ -80, -100, 80, -40 },
        .state = gui.Button.State.Disabled,
        .alignment = gui.Alignment.center_center,
    });

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

        gui_state.pushEvent(Event{ .size = vpsize });
        gui_state.pushEvent(Event{ .pos = glfw.cursorPos() });
        if (glfw.isClicked(0)) {
            gui_state.pushEvent(Event{ .click = 0 });
        }

        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glEnable(c.GL_DEPTH_TEST);
        // 3D

        // ...

        c.glDisable(c.GL_DEPTH_TEST);
        // 2D

        renderer.color = Color{ 0.8, 0.141, 0.113, 1.0 };
        renderer.draw(gui_state);

        window.swapBuffers();
        glfw.pollEvents();
    }
}
