const c = @import("c.zig");
const std = @import("std");
const linmath = @import("linmath.zig");
const Vec3 = linmath.F32x3;
const Mat = linmath.Mat;
const sdl = @import("sdl.zig");
const mesh = @import("mesh.zig");
const shader = @import("shader.zig");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");
const Renderer = @import("renderer.zig").Renderer;
const Event = @import("events.zig").Event;
const shape = @import("shape.zig");

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 900;

pub fn main() !void {
    try sdl.init();
    defer sdl.destroy();

    var window = try sdl.Window.init("krateroid", WINDOW_WIDTH, WINDOW_HEIGHT);
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

    renderer.vpsize = window.size;
    renderer.camera.proj = linmath.Scale(.{
        @intToFloat(f32, window.size[1]) / @intToFloat(f32, window.size[0]) * 0.1,
        0.1,
        0.001,
    });
    renderer.camera.rot[0] = std.math.pi / 6.0;

    var gui_main_menu = gui.Gui.init();
    defer gui_main_menu.destroy();

    try gui_main_menu.addButton(gui.Button.init(
        gui.Rect{ -90, 40, 90, 100 },
        gui.Alignment.center_center,
        std.unicode.utf8ToUtf16LeStringLiteral("продолжить"),
    ));
    try gui_main_menu.addButton(gui.Button.init(
        gui.Rect{ -90, -30, 90, 30 },
        gui.Alignment.center_center,
        std.unicode.utf8ToUtf16LeStringLiteral("настройки"),
    ));
    try gui_main_menu.addButton(gui.Button.init(
        gui.Rect{ -90, -100, 90, -40 },
        gui.Alignment.center_center,
        std.unicode.utf8ToUtf16LeStringLiteral("выход"),
    ));

    const Control = struct {
        move: struct {
            up: bool = false,
            left: bool = false,
            down: bool = false,
            right: bool = false,
        },
        rotate: struct {
            up: bool = false,
            left: bool = false,
            down: bool = false,
            right: bool = false,
        },
    };

    var control = Control{ .move = .{}, .rotate = .{} };

    const camera_speed = 0.01;
    const camera_rotate_speed = std.math.pi / 720.0;

    var is_show_f3 = false;

    var last_time = @intCast(i32, c.SDL_GetTicks());
    var run = true;

    var frame: u32 = 0;
    var fps: u32 = 0;
    var seconds: u32 = 0;

    while (run) {
        const current_time = @intCast(i32, c.SDL_GetTicks());
        const dt: f32 = @intToFloat(f32, current_time - last_time);
        last_time = current_time;

        while (true) {
            const event = sdl.pollEvent();
            if (event == null) break;
            switch (event.?) {
                Event.quit => run = false,
                Event.key_down => |key| {
                    switch (key) {
                        c.SDLK_ESCAPE => gui_main_menu.enable = !gui_main_menu.enable,
                        c.SDLK_F3 => is_show_f3 = !is_show_f3,
                        c.SDLK_w => control.move.up = true,
                        c.SDLK_a => control.move.left = true,
                        c.SDLK_s => control.move.down = true,
                        c.SDLK_d => control.move.right = true,
                        c.SDLK_UP => control.rotate.up = true,
                        c.SDLK_LEFT => control.rotate.left = true,
                        c.SDLK_DOWN => control.rotate.down = true,
                        c.SDLK_RIGHT => control.rotate.right = true,
                        else => {},
                    }
                },
                Event.key_up => |key| {
                    switch (key) {
                        c.SDLK_w => control.move.up = false,
                        c.SDLK_a => control.move.left = false,
                        c.SDLK_s => control.move.down = false,
                        c.SDLK_d => control.move.right = false,
                        c.SDLK_UP => control.rotate.up = false,
                        c.SDLK_LEFT => control.rotate.left = false,
                        c.SDLK_DOWN => control.rotate.down = false,
                        c.SDLK_RIGHT => control.rotate.right = false,
                        else => {},
                    }
                },
                Event.window_size => |size| {
                    window.size = size;
                    renderer.camera.proj = linmath.Scale(.{
                        @intToFloat(f32, window.size[1]) / @intToFloat(f32, window.size[0]) * 0.1,
                        0.1,
                        0.001,
                    });
                    c.glViewport(0, 0, size[0], size[1]);
                },
                else => {},
            }
            const gui_event = gui_main_menu.pollEvent(event.?);
            switch (gui_event) {
                gui.GuiEvent.button_up => |id| {
                    switch (id) {
                        0 => gui_main_menu.enable = false,
                        2 => run = false,
                        else => {},
                    }
                },
                else => {},
            }
        }

        const vpsize = window.size;
        renderer.vpsize = vpsize;

        if (control.move.up) {
            renderer.camera.pos[0] -= @sin(renderer.camera.rot[2]) * camera_speed * dt;
            renderer.camera.pos[1] += @cos(renderer.camera.rot[2]) * camera_speed * dt;
        }
        if (control.move.left) {
            renderer.camera.pos[0] -= @cos(renderer.camera.rot[2]) * camera_speed * dt;
            renderer.camera.pos[1] -= @sin(renderer.camera.rot[2]) * camera_speed * dt;
        }
        if (control.move.down) {
            renderer.camera.pos[0] += @sin(renderer.camera.rot[2]) * camera_speed * dt;
            renderer.camera.pos[1] -= @cos(renderer.camera.rot[2]) * camera_speed * dt;
        }
        if (control.move.right) {
            renderer.camera.pos[0] += @cos(renderer.camera.rot[2]) * camera_speed * dt;
            renderer.camera.pos[1] += @sin(renderer.camera.rot[2]) * camera_speed * dt;
        }
        if (control.rotate.up) renderer.camera.rot[0] += camera_rotate_speed * dt;
        if (control.rotate.right) renderer.camera.rot[2] += camera_rotate_speed * dt;
        if (control.rotate.down) renderer.camera.rot[0] -= camera_rotate_speed * dt;
        if (control.rotate.left) renderer.camera.rot[2] -= camera_rotate_speed * dt;
        renderer.camera.view = linmath.MatIdentity;
        renderer.camera.view = linmath.mul(renderer.camera.view, linmath.Pos(-renderer.camera.pos));
        renderer.camera.view = linmath.mul(renderer.camera.view, linmath.Rot(renderer.camera.rot));

        // Рисование
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glEnable(c.GL_DEPTH_TEST);
        // 3D

        renderer.draw(shape.Quad{ .size = .{ 16.0, 16.0, 1.0 } });

        // ...

        c.glDisable(c.GL_DEPTH_TEST);
        // 2D

        renderer.color = .{ 1.0, 1.0, 1.0, 1.0 };
        if (gui_main_menu.enable) renderer.draw(gui_main_menu);

        if (is_show_f3) {
            if (@divTrunc(c.SDL_GetTicks(), 1000) > seconds) {
                seconds = @divTrunc(c.SDL_GetTicks(), 1000);
                fps = frame;
                frame = 0;
            }

            renderer.gui.rect.color = .{ 0.0, 0.0, 0.0, 0.5 };
            renderer.gui.rect.border.width = 0;
            renderer.gui.rect.alignment = gui.Alignment.left_bottom;
            renderer.draw(gui.Rect{
                0,
                0,
                window.size[0],
                28,
            });
            renderer.draw(gui.Text{
                .data = std.unicode.utf8ToUtf16LeStringLiteral("krateroid 0.0.3 alpha"),
                .pos = linmath.I32x2{ 2, 6 },
            });

            renderer.gui.rect.alignment = gui.Alignment.left_top;
            renderer.draw(gui.Rect{
                0,
                -102,
                window.size[0],
                0,
            });
            var buf: [500]u8 = [_]u8{0} ** 500;
            _ = try std.fmt.bufPrint(&buf, "fps {}\nCamera\n|-pos {}\n|-rot: {}", .{
                fps,
                renderer.camera.pos,
                renderer.camera.rot,
            });
            renderer.draw(gui.Text{
                .data = try std.unicode.utf8ToUtf16LeWithNull(std.heap.page_allocator, buf[0..]),
                .pos = linmath.I32x2{ 2, -24 },
                .alignment = gui.Alignment.left_top,
            });
        }

        frame += 1;

        window.swap();
    }
}
