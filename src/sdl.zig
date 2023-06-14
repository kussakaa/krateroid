const c = @import("c.zig");
const std = @import("std");
const print = std.debug.print;
const panic = std.debug.panic;
const I32x2 = @import("linmath.zig").I32x2;
const Event = @import("events").Event;

pub fn init() !void {
    if (c.SDL_Init(c.SDL_INIT_EVERYTHING) < 0) {
        panic("[!!!ERROR!!!]:[SDL2]:Initiased! {s}\n", .{c.SDL_GetError()});
    } else {
        print("[*SUCCES*]:[SDL2]:Initialised\n", .{});
    }
}

pub fn quit() void {
    c.SDL_Quit();
}

pub const Window = struct {
    handle: ?*c.SDL_Window,
    title: [*c]const u8,
    size: I32x2,

    pub fn init(title: [*c]const u8, width: i32, height: i32) !Window {
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_FLAGS, c.SDL_GL_CONTEXT_PROFILE_CORE);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
        const handle = c.SDL_CreateWindow(
            title,
            c.SDL_WINDOWPOS_CENTERED,
            c.SDL_WINDOWPOS_CENTERED,
            @intCast(c_int, width),
            @intCast(c_int, height),
            c.SDL_WINDOW_OPENGL,
        );

        if (handle == null) {
            std.debug.panic("[!!!ERROR!!!]:[WINDOW]:Initialize: {s}", .{c.SDL_GetError()});
        }

        const context = c.SDL_GL_CreateContext(handle);
        _ = c.SDL_GL_MakeCurrent(handle, context);
        if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.SDL_GL_GetProcAddress)) == 0) {
            panic("[!!!ERROR!!!]:[WINDOW]:[GLCONTEXT]:Initialised\n", .{});
        }

        c.glViewport(0, 0, width, height);

        print("[*SUCCES*]:[WINDOW]:[Title:{s}|Width:{}|Height:{}]:Initialised\n", .{ title, width, height });
        return Window{ .handle = handle, .title = title, .size = I32x2{ width, height } };
    }

    pub fn swap(self: Window) void {
        c.SDL_GL_SwapWindow(self.handle);
    }

    pub fn destroy(self: Window) void {
        print("[*SUCCES*]:[WINDOW]:[Title:{s}]:Destroyed\n", .{self.title});
        c.SDL_DestroyWindow(self.handle);
    }
};
