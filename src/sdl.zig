const c = @import("c.zig");
const std = @import("std");
const I32x2 = @import("linmath.zig").I32x2;
const Event = @import("input.zig").Event;

pub fn init() !void {
    if (c.SDL_Init(c.SDL_INIT_EVERYTHING) < 0) {
        std.log.err("failed init SDL: {s}", .{c.SDL_GetError()});
    } else {
        std.log.debug("init sdl", .{});
    }
}

pub fn deinit() void {
    std.log.debug("deinit sdl", .{});
    c.SDL_Quit();
}

pub const Window = struct {
    handle: ?*c.SDL_Window,
    context: c.SDL_GLContext,
    title: [*c]const u8,
    size: I32x2,

    pub fn init(title: [*c]const u8, width: i32, height: i32) !Window {
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_FLAGS, c.SDL_GL_CONTEXT_PROFILE_CORE);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
        //_ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLEBUFFERS, 1);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLESAMPLES, 4);
        const handle = c.SDL_CreateWindow(
            title,
            c.SDL_WINDOWPOS_CENTERED,
            c.SDL_WINDOWPOS_CENTERED,
            @as(c_int, @intCast(width)),
            @as(c_int, @intCast(height)),
            c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_RESIZABLE,
        );

        if (handle == null) {
            std.log.err("failed init window: {s}", .{c.SDL_GetError()});
        }

        const context = c.SDL_GL_CreateContext(handle);
        _ = c.SDL_GL_MakeCurrent(handle, context);
        if (c.gladLoadGLLoader(@as(c.GLADloadproc, @ptrCast(&c.SDL_GL_GetProcAddress))) == 0) {
            std.log.err("failed init gl functions", .{});
        }

        _ = c.SDL_GL_SetSwapInterval(0);

        c.glViewport(0, 0, width, height);

        const window = Window{ .handle = handle, .context = context, .title = title, .size = I32x2{ width, height } };
        std.log.debug("init window = {}", .{window});
        return window;
    }

    pub fn swap(self: Window) void {
        c.SDL_GL_SwapWindow(self.handle);
    }

    pub fn deinit(self: Window) void {
        std.log.debug("deinit window = {}", .{self});
        c.SDL_DestroyWindow(self.handle);
        c.SDL_GL_DeleteContext(self.context);
    }
};

pub fn pollEvent() ?Event {
    var sdl_event: c.SDL_Event = undefined;
    if (c.SDL_PollEvent(&sdl_event) <= 0) return null;
    return switch (sdl_event.type) {
        c.SDL_QUIT => Event.quit,
        c.SDL_KEYDOWN => Event{ .key_down = sdl_event.key.keysym.sym },
        c.SDL_KEYUP => Event{ .key_up = sdl_event.key.keysym.sym },
        c.SDL_MOUSEMOTION => Event{ .mouse_motion = I32x2{ sdl_event.motion.x, sdl_event.motion.y } },
        c.SDL_MOUSEBUTTONDOWN => Event{ .mouse_button_down = @enumFromInt(sdl_event.button.button) },
        c.SDL_MOUSEBUTTONUP => Event{ .mouse_button_up = @enumFromInt(sdl_event.button.button) },
        c.SDL_WINDOWEVENT => switch (sdl_event.window.event) {
            c.SDL_WINDOWEVENT_SIZE_CHANGED => Event{ .window_size = I32x2{ sdl_event.window.data1, sdl_event.window.data2 } },
            else => Event.none,
        },
        else => Event.none,
    };
}
