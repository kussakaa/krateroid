window: Window,
input: Input,

pub const Config = struct {
    window: Window.Config,
    input: Input.Config,
};

pub fn init(allocator: Allocator, config: Config) anyerror!Self {
    try glfw.init();

    const window = try Window.init(config.window);
    const input = try Input.init(allocator, window, config.input);

    imgui.init(allocator);
    imgui.backend.init(window.handle);

    stb.init(allocator);

    log.succes(.init, "GFX System", .{});

    return .{
        .window = window,
        .input = input,
    };
}

pub fn deinit(self: Self) void {
    stb.deinit();

    imgui.backend.deinit();
    imgui.deinit();

    self.input.deinit();
    self.window.deinit();
    glfw.terminate();
}

pub fn update(self: Self) bool {
    self.input.update();
    if (self.window.handle.shouldClose() or
        self.input.isJustPressed(.escape))
        return false;

    return true;
}

pub fn clear(self: Self) void {
    _ = self;
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
}

pub fn swapBuffers(self: Self) void {
    self.window.handle.swapBuffers();
}

pub const Window = @import("Gfx/Window.zig");
pub const Input = @import("Gfx/Input.zig");
pub const Camera = @import("Gfx/Camera.zig");
pub const Buffer = @import("Gfx/Buffer.zig");
pub const Mesh = @import("Gfx/Mesh.zig");
pub const Shader = @import("Gfx/Shader.zig");
pub const Program = @import("Gfx/Program.zig");
pub const Uniform = @import("Gfx/Uniform.zig");
pub const Texture = @import("Gfx/Texture.zig");

const Self = @This();
const Allocator = std.mem.Allocator;

const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const imgui = @import("zgui");
const stb = @import("zstbi");
const log = @import("log");
const std = @import("std");
