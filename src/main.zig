const c = @import("c.zig");
const std = @import("std");
const linmath = @import("linmath.zig");
const Mat = linmath.Mat;
const sdl = @import("sdl.zig");
const gl = @import("gl.zig");
const gui = @import("gui.zig");
const input = @import("input.zig");
const shape = @import("shape.zig");
const world = @import("world.zig");

const U16 = std.unicode.utf8ToUtf16LeStringLiteral;

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;

pub fn main() !void {
    try sdl.init();
    defer sdl.deinit();

    var window = try sdl.Window.init("krateroid", WINDOW_WIDTH, WINDOW_HEIGHT);
    defer window.deinit();

    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_CULL_FACE);
    c.glEnable(c.GL_BLEND);
    c.glEnable(c.GL_MULTISAMPLE);
    c.glCullFace(c.GL_FRONT);
    c.glFrontFace(c.GL_CW);
    c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL);
    c.glLineWidth(1);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);

var input_state = input.State.init();

    var gui_state = try gui.State.init(std.heap.page_allocator, .{ WINDOW_WIDTH, WINDOW_HEIGHT });
    defer gui_state.deinit();

    const gui_text_style = gui.Text.Style{
        .color = .{ 1.0, 1.0, 1.0, 1.0 },
    };

    const gui_button_style = gui.Button.Style{
        .states = .{
            .{ .text = gui_text_style, .texture = try gl.Texture.init("data/gui/button/empty.png") },
            .{ .text = gui_text_style, .texture = try gl.Texture.init("data/gui/button/focus.png") },
            .{ .text = gui_text_style, .texture = try gl.Texture.init("data/gui/button/press.png") },
        },
    };
    defer gui_button_style.states[0].texture.deinit();
    defer gui_button_style.states[1].texture.deinit();
    defer gui_button_style.states[2].texture.deinit();

    // кнопка играть
    _ = try gui_state.button(.{
        .rect = .{ .min = .{ -32, -17 }, .max = .{ 32, -1 } },
        .alignment = .{ .horizontal = .center, .vertical = .center },
        .text = U16("играть"),
        .style = gui_button_style,
    });

    // кнопка выход
    const button_exit = try gui_state.button(.{
        .rect = .{ .min = .{ -32, 1 }, .max = .{ 32, 17 } },
        .alignment = .{ .horizontal = .center, .vertical = .center },
        .text = U16("выход"),
        .style = gui_button_style,
    });

    // F3
    _ = try gui_state.text(.{
        .data = U16("krateroid prototype gui"),
        .pos = .{ 2, 1 },
        .style = gui_text_style,
    });

    // счётчик кадров в секунду
    const text_fps = try gui_state.text(.{
        .data = U16("fps:$$$$$$"),
        .pos = .{ 2, 9 },
        .usage = .dynamic,
        .style = gui_text_style,
    });

    var chunk = try world.Chunk.init(.{
        .pos = .{ 0, 0 },
    });

    chunk.hmap[4][4] = 64;
    chunk.hmap[4][5] = 64;
    chunk.hmap[5][4] = 64;
    chunk.hmap[5][5] = 64;

    var last_time = @as(i32, @intCast(c.SDL_GetTicks()));
    var run = true;

    var frame: u32 = 0;
    var fps: u32 = 0;
    var seconds: u32 = 0;

    while (run) {
        const current_time = @as(i32, @intCast(c.SDL_GetTicks()));
        const dt: f32 = @as(f32, @floatFromInt(current_time - last_time)) / 1000.0;
        _ = dt;
        last_time = current_time;

        if (@divTrunc(c.SDL_GetTicks(), 1000) > seconds) {
            seconds = @divTrunc(c.SDL_GetTicks(), 1000);
            fps = frame;
            frame = 0;

            var buf: [10]u8 = [1]u8{'$'} ** 10;
            _ = try std.fmt.bufPrint(&buf, "fps:{}", .{fps});
            var buf16: [10]u16 = [1]u16{'$'} ** 10;
            const len16 = try std.unicode.utf8ToUtf16Le(buf16[0..], buf[0..]);
            try text_fps.subdata(gui_state, buf16[0..len16]);
        }

        while (true) {
            const event = sdl.pollEvent();
            if (event == .none) break;
            input_state.process(event);
            //std.log.debug("event: {}", .{event.?});
            switch (event) {
                .quit => run = false,
                .window_size => |size| {
                    window.size = size;
                    gui_state.vpsize = size;
                    c.glViewport(0, 0, size[0], size[1]);
                },
                .keyboard_key_down => |key| {
                    switch (key) {
                        c.SDL_SCANCODE_P => gui_state.scale += 1,
                        c.SDL_SCANCODE_O => gui_state.scale -= 1,
                        else => {},
                    }
                },
                else => {},
            }

            const gui_event = gui.EventSystem.process(gui_state, input_state, event);
            if (gui_event != .none) std.log.debug("gui event: {}", .{gui_event});

            switch (gui_event) {
                .unpress => |id| {
                    if (id == button_exit.id) run = false;
                },
                else => {},
            }
        }

        gui.InputSystem.process(&gui_state, input_state);

        // Рисование
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glEnable(c.GL_DEPTH_TEST);
        c.glDisable(c.GL_DEPTH_TEST);

        try gui.RenderSystem.draw(gui_state);

        frame += 1;
        window.swap();
    }
}
