window: Window,
camera: Camera,

pub fn init(config: Config) anyerror!Gfx {
    try glfw.init();

    const window = try Window.init(config.window);

    imgui.init(config.allocator);
    imgui.backend.init(window.handle);

    stb.init(config.allocator);

    const camera = Camera.init(config.camera);

    const program = try Program.init(.{
        .allocator = config.allocator,
        .name = "world",
    });
    defer program.deinit();

    log.succes("Initialization GFX", .{});

    return .{
        .window = window,
        .camera = camera,
    };
}

pub fn deinit(self: *Gfx) void {
    stb.deinit();
    imgui.backend.deinit();
    imgui.deinit();
    self.window.deinit();
    glfw.terminate();
    self.* = undefined;
}

pub fn update(self: *Gfx) bool {
    glfw.pollEvents();
    if (self.window.handle.shouldClose() or
        self.window.handle.getKey(.escape) == .press)
        return false;

    self.camera.update();
    return true;
}

pub fn draw(self: *Gfx) bool {
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);

    const fb_size = self.window.handle.getFramebufferSize();
    gl.viewport(0, 0, fb_size[0], fb_size[1]);
    imgui.backend.newFrame(@intCast(fb_size[0]), @intCast(fb_size[1]));

    if (imgui.begin("Camera", .{})) {
        _ = imgui.sliderFloat4("pos", .{ .v = &self.camera.pos, .min = 0.0, .max = 32.0 });
        _ = imgui.sliderFloat4("rot", .{ .v = &self.camera.rot, .min = 0.0, .max = std.math.pi * 2 });
        _ = imgui.sliderFloat("scale", .{ .v = &self.camera.scale, .min = 0.1, .max = 32.0 });
        _ = imgui.sliderFloat("ratio", .{ .v = &self.camera.ratio, .min = 0.5, .max = 2.0 });
    }
    imgui.end();

    imgui.backend.draw();
    self.window.handle.swapBuffers();

    return true;
}

const Gfx = @This();

pub const Config = struct {
    allocator: Allocator,
    window: Window.Config,
    camera: Camera.Config,
};

pub const Window = @import("Gfx/Window.zig");
pub const Camera = @import("Gfx/Camera.zig");
pub const Buffer = @import("Gfx/Buffer.zig");
pub const Mesh = @import("Gfx/Mesh.zig");
pub const Shader = @import("Gfx/Shader.zig");
pub const Program = @import("Gfx/Program.zig");
pub const Uniform = @import("Gfx/Uniform.zig");
pub const Texture = @import("Gfx/Texture.zig");

const Allocator = std.mem.Allocator;

const TermColor = @import("terminal").Color;

const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const gl_major = 3;
const gl_minor = 3;
const stb = @import("zstbi");
const imgui = @import("zgui");

const std = @import("std");
const log = @import("log.zig");
