const c = @import("c.zig");
const std = @import("std");
const linmath = @import("linmath.zig");
const Vec = linmath.Vec;
const Color = linmath.F32x4;
const Mat = linmath.Mat;
const sdl = @import("sdl.zig");
const mesh = @import("mesh.zig");
const shader = @import("shader.zig");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");
const Renderer = @import("renderer.zig").Renderer;
const Event = @import("events.zig").Event;

pub fn main() !void {
    try sdl.init();
    defer sdl.quit();

    var window = try sdl.Window.init("krateroid", 800, 600);
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

    var gui_main_menu = gui.Gui.init();
    try gui_main_menu.addButton(gui.Button{
        .rect = gui.Rect{ -80, 40, 80, 100 },
        .alignment = gui.Alignment.center_center,
    });
    try gui_main_menu.addButton(gui.Button{
        .rect = gui.Rect{ -80, -30, 80, 30 },
        .alignment = gui.Alignment.center_center,
    });
    try gui_main_menu.addButton(gui.Button{
        .rect = gui.Rect{ -80, -100, 80, -40 },
        .alignment = gui.Alignment.center_center,
    });

    //var last_time = @floatCast(f32, c.glfwGetTime());

    var event: c.SDL_Event = undefined;
    var run = true;

    while (run) {

        //const current_time = @floatCast(f32, c.glfwGetTime());
        //const dt = current_time - last_time;
        //last_time = current_time;
        //_ = dt;

        while (c.SDL_PollEvent(&event) > 0) {
            switch (event.type) {
                c.SDL_QUIT => run = false,
                c.SDL_KEYDOWN => {
                    switch (event.key.keysym.sym) {
                        c.SDLK_ESCAPE => {
                            gui_main_menu.enable = !gui_main_menu.enable;
                            gui_main_menu.update();
                        },
                        else => {},
                    }
                },
                c.SDL_MOUSEMOTION => {
                    const mouse_pos = linmath.I32x2{ event.motion.x, window.size[1] - event.motion.y };
                    gui_main_menu.pushEvent(Event{ .mouse_motion = mouse_pos });
                },
                c.SDL_MOUSEBUTTONDOWN => {
                    switch (event.button.button) {
                        c.SDL_BUTTON_LEFT => {
                            gui_main_menu.pushEvent(Event{ .mouse_button_down = 0 });
                        },
                        else => {},
                    }
                },
                c.SDL_MOUSEBUTTONUP => {
                    switch (event.button.button) {
                        c.SDL_BUTTON_LEFT => {
                            gui_main_menu.pushEvent(Event{ .mouse_button_up = 0 });
                        },
                        else => {},
                    }
                },
                c.SDL_WINDOWEVENT => {
                    if (event.window.event == c.SDL_WINDOWEVENT_SIZE_CHANGED) {
                        window.size = linmath.I32x2{ event.window.data1, event.window.data2 };
                        gui_main_menu.pushEvent(Event{ .window_size = window.size });
                        c.glViewport(0, 0, event.window.data1, event.window.data2);
                    }
                },
                else => {},
            }
        }

        const vpsize = window.size;
        renderer.vpsize = vpsize;

        if (gui_main_menu.buttons.items[0].state == gui.Button.State.Unpushed) {
            gui_main_menu.update();
            gui_main_menu.enable = false;
        }

        if (gui_main_menu.buttons.items[2].state == gui.Button.State.Unpushed) {
            run = false;
        }

        // Рисование
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glEnable(c.GL_DEPTH_TEST);
        // 3D

        // ...

        c.glDisable(c.GL_DEPTH_TEST);
        // 2D

        renderer.color = Color{ 1.0, 1.0, 1.0, 1.0 };
        if (gui_main_menu.enable) renderer.draw(gui_main_menu);

        window.swap();
    }
}
