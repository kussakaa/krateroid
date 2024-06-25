const std = @import("std");
const log = std.log;
const zm = @import("zmath");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const zgui = @import("zgui");

const World = @import("World.zig");
const Camera = @import("Camera.zig");
const Window = @import("Window.zig");
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

    var window = try Window.init(.{
        .title = "krateroid",
        .size = .{ 1200, 800 },
    });
    defer window.deinit();

    var camera = Camera.init(.{
        .ratio = 1.0,
        .scale = 1.0,
    });
    defer camera.deinit();

    var drawer = try Drawer.init(.{
        .allocator = allocator,
    });

    defer drawer.deinit();

    zgui.init(allocator);
    defer zgui.deinit();

    zgui.backend.init(window.handle);
    defer zgui.backend.deinit();

    var show_fps = false;
    var show_grid = false;

    loop: while (true) {
        if (window.handle.shouldClose() or
            window.handle.getKey(.escape) == .press)
            break :loop;

        glfw.pollEvents();

        camera.update();

        gl.clear(gl.COLOR_BUFFER_BIT);
        gl.clearColor(0.0, 0.0, 0.0, 1.0);

        const fb_size = window.handle.getFramebufferSize();
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
        window.handle.swapBuffers();
    }
}
