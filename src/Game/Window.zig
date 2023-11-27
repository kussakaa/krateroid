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
    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_CULL_FACE);
    c.glEnable(c.GL_BLEND);
    c.glEnable(c.GL_MULTISAMPLE);
    c.glCullFace(c.GL_FRONT);
    c.glFrontFace(c.GL_CW);
    c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL);
    c.glLineWidth(1);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);

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
    const current_time = @as(f32, @floatFromInt(c.SDL_GetTicks()));
    const dt: f32 = (current_time - self.last_time) / 1000.0;
    self.last_time = current_time;
    self.dt = dt;
    c.SDL_GL_SwapWindow(self.handle);
}

pub fn resize(self: *Window, size: @Vector(2, i32)) void {
    self.size = size;
    c.glViewport(0, 0, size[0], size[1]);
}
