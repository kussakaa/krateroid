handle: *glfw.Window,

pub fn init(config: Config) !Window {
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.opengl_forward_compat, false);
    glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);

    const handle = try glfw.Window.create(
        config.size[0],
        config.size[1],
        config.title,
        null,
    );

    glfw.makeContextCurrent(handle);
    glfw.swapInterval(1);

    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);

    _ = handle.setSizeCallback(sizeCallback);

    log.succes(.init, "GFX Window", .{});

    return .{ .handle = handle };
}

pub fn deinit(self: Window) void {
    self.handle.destroy();
}

pub fn sizeCallback(_: *glfw.Window, width: i32, height: i32) callconv(.C) void {
    gl.viewport(0, 0, width, height);
}

const Window = @This();

pub const Config = struct {
    title: [:0]const u8 = "window",
    size: @Vector(2, i32) = .{ 800, 600 },
};

const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const gl_major = 3;
const gl_minor = 3;

const std = @import("std");
const log = @import("log");
