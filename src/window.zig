const std = @import("std");
const log = std.log.scoped(.window);
const c = @import("c.zig");
const Allocator = std.mem.Allocator;
const Pos = @Vector(2, i32);
const Size = @Vector(2, i32);
const Color = @Vector(4, f32);

var handle: ?*c.SDL_Window = undefined;
var context: c.SDL_GLContext = undefined;
pub var title: []const u8 = undefined;
pub var size: Size = undefined;
pub var ratio: f32 = undefined;
pub var time: u32 = 0;
pub var frame: u32 = 0;
pub var fps: u32 = 0;

pub fn init(info: struct {
    title: []const u8 = "window",
    size: Size = .{ 800, 600 },
}) !void {
    if (c.SDL_Init(c.SDL_INIT_EVERYTHING) < 0) {
        log.err("init sdl failed {s}", .{c.SDL_GetError()});
        return error.SDL_INIT;
    }

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_FLAGS, c.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
    //_ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLEBUFFERS, 1);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLESAMPLES, 4);

    title = info.title;
    size = info.size;
    ratio = @as(f32, @floatFromInt(size[0])) / @as(f32, @floatFromInt(size[1]));
    const ctitle: [*c]const u8 = @ptrCast(info.title);
    handle = c.SDL_CreateWindow(
        ctitle,
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        @as(c_int, @intCast(size[0])),
        @as(c_int, @intCast(size[1])),
        c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_RESIZABLE,
    );

    if (handle == null) {
        log.err("init {s}", .{c.SDL_GetError()});
        return error.WINDOW_INIT;
    }
    context = c.SDL_GL_CreateContext(handle);
    _ = c.SDL_GL_MakeCurrent(handle, context);
    if (c.gladLoadGLLoader(@as(c.GLADloadproc, @ptrCast(&c.SDL_GL_GetProcAddress))) == 0) {
        log.err("init gl functions failed", .{});
        return error.GL_INIT;
    }

    _ = c.SDL_GL_SetSwapInterval(0);

    c.glViewport(0, 0, size[0], size[1]);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_CULL_FACE);
    c.glEnable(c.GL_BLEND);
    c.glEnable(c.GL_MULTISAMPLE);
    c.glCullFace(c.GL_FRONT);
    c.glFrontFace(c.GL_CW);
    c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL);
    c.glLineWidth(2);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    log.debug("init {s}:{}", .{ title, size });
}

pub fn deinit() void {
    log.debug("deinit {s}:{}", .{ title, size });
    c.SDL_DestroyWindow(handle);
    c.SDL_GL_DeleteContext(context);
}

pub fn clear(info: struct {
    color: Color = .{ 0.0, 0.0, 0.0, 1.0 },
}) void {
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    c.glClearColor(info.color[0], info.color[1], info.color[2], info.color[3]);
}

pub fn swap() void {
    time = c.SDL_GetTicks();
    frame += 1;

    const s = struct {
        var sec_cntr: u32 = 0;
        var fps_cntr: u32 = 0;
    };

    s.fps_cntr += 1;

    if (time - s.sec_cntr * 1000 > 1000) {
        fps = s.fps_cntr;
        s.fps_cntr = 0;
        s.sec_cntr += 1;
    }

    c.SDL_GL_SwapWindow(handle);
}

pub fn resize(psize: Size) void {
    size = psize;
    ratio = @as(f32, @floatFromInt(size[0])) / @as(f32, @floatFromInt(size[1]));
    c.glViewport(0, 0, size[0], size[1]);
}
