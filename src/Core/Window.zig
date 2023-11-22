const c = @import("../c.zig");
const log = @import("std").log.scoped(.Window);

const Window = @This();

handle: ?*c.SDL_Window,
context: c.SDL_GLContext,
title: []const u8,
size: @Vector(2, i32),
last_time: f32 = 0.0,
dt: f32 = 1.0,

pub const InitInfo = struct {
    title: []const u8,
    size: @Vector(2, i32) = .{ 800, 600 },
};

pub fn init(info: InitInfo) !Window {
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_FLAGS, c.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
    //_ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLEBUFFERS, 1);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLESAMPLES, 4);

    const ctitle: [*c]const u8 = @ptrCast(info.title);
    const handle = c.SDL_CreateWindow(
        ctitle,
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        @as(c_int, @intCast(info.size[0])),
        @as(c_int, @intCast(info.size[1])),
        c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_RESIZABLE,
    );

    if (handle == null) {
        log.err("init {s}", .{c.SDL_GetError()});
        return error.WindowInit;
    }

    const context = c.SDL_GL_CreateContext(handle);
    _ = c.SDL_GL_MakeCurrent(handle, context);
    if (c.gladLoadGLLoader(@as(c.GLADloadproc, @ptrCast(&c.SDL_GL_GetProcAddress))) == 0) {
        log.err("init gl functions", .{});
        return error.GLInit;
    }

    _ = c.SDL_GL_SetSwapInterval(0);

    c.glViewport(0, 0, info.size[0], info.size[1]);

    const window = Window{ .handle = handle, .context = context, .title = info.title, .size = info.size };
    log.debug("init {}", .{window});
    return window;
}

pub fn deinit(self: Window) void {
    log.debug("deinit {}", .{self});
    c.SDL_DestroyWindow(self.handle);
    c.SDL_GL_DeleteContext(self.context);
}

pub fn swap(self: *Window) void {
    const S = struct {
        var lasttime: f32 = 0.0;
    };

    const current_time = @as(i32, @intCast(c.SDL_GetTicks()));
    const dt: f32 = @as(f32, @floatFromInt(current_time - S.last_time)) / 1000.0;
    self.last_time = current_time;
    self.dt = dt;
    c.SDL_GL_SwapWindow(self.handle);
}
