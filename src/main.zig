const std = @import("std");
const log = std.log;
const zm = @import("zmath");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const zgui = @import("zgui");

const World = @import("World.zig");
const Camera = @import("Camera.zig");
const Drawer = @import("Drawer.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator: std.mem.Allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var world = try World.init(.{
        .allocator = allocator,
        .width = 4,
    });
    defer world.deinit();

    try glfw.init();
    defer glfw.terminate();

    const gl_major = 3;
    const gl_minor = 3;
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.opengl_forward_compat, false);
    glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);

    const window = try glfw.Window.create(1200, 900, "krateroid", null);
    defer window.destroy();

    glfw.makeContextCurrent(window);
    glfw.swapInterval(1);

    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);

    var camera = Camera.init(.{
        .ratio = 1.0,
        .scale = 1.0,
    });

    var drawer = try Drawer.init(.{
        .allocator = allocator,
        .window = window,
        .camera = &camera,
        .world = &world,
    });

    defer drawer.deinit();

    zgui.init(allocator);
    defer zgui.deinit();

    zgui.backend.init(window);
    defer zgui.backend.deinit();

    var show_fps = false;
    var show_grid = false;

    loop: while (true) {
        if (window.shouldClose() or
            window.getKey(.escape) == .press)
            break :loop;

        glfw.pollEvents();

        camera.update();

        gl.clear(gl.COLOR_BUFFER_BIT);
        gl.clearColor(0.0, 0.0, 0.0, 1.0);

        const fb_size = window.getFramebufferSize();
        gl.viewport(0, 0, fb_size[0], fb_size[1]);
        zgui.backend.newFrame(@intCast(fb_size[0]), @intCast(fb_size[1]));

        if (zgui.begin("Debug", .{})) {
            _ = zgui.checkbox("show fps", .{ .v = &show_fps });
            _ = zgui.checkbox("show grid", .{ .v = &show_grid });
        }
        zgui.end();

        if (zgui.begin("Camera", .{})) {
            _ = zgui.sliderFloat4("pos", .{ .v = &camera.pos, .min = 0.0, .max = 32.0 });
            _ = zgui.sliderFloat4("rot", .{ .v = &camera.rot, .min = 0.0, .max = std.math.pi * 2 });
            _ = zgui.sliderFloat("scale", .{ .v = &camera.scale, .min = 0.1, .max = 32.0 });
            _ = zgui.sliderFloat("ratio", .{ .v = &camera.ratio, .min = 0.5, .max = 2.0 });
        }
        zgui.end();

        zgui.backend.draw();
        window.swapBuffers();
    }
}
