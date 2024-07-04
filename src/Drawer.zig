gfx: Gfx,
camera: Gfx.Camera,

pub const Config = struct {
    gfx: Gfx,
    camera: Gfx.Camera.Config,
};

pub fn init(config: Config) !Self {
    log.succes(.init, "DRAWER", .{});

    return .{
        .gfx = config.gfx,
        .camera = Gfx.Camera.init(config.camera),
    };
}

pub fn deinit(self: Self) void {
    _ = self;
}

pub fn draw(self: *Self) bool {
    // CLEAR

    self.gfx.clear();

    // WORLD
    //if (self.world) |_| {}

    // GUi
    //if (self.gui) |_| {}

    // IMGUI
    const fb_size = self.gfx.window.handle.getFramebufferSize();
    imgui.backend.newFrame(@intCast(fb_size[0]), @intCast(fb_size[1]));

    if (imgui.begin("Camera", .{})) {
        _ = imgui.sliderFloat4("pos", .{ .v = &self.camera.pos, .min = 0.0, .max = 32.0 });
        _ = imgui.sliderFloat4("rot", .{ .v = &self.camera.rot, .min = 0.0, .max = std.math.pi * 2 });
        _ = imgui.sliderFloat("scale", .{ .v = &self.camera.scale, .min = 0.1, .max = 32.0 });
        _ = imgui.sliderFloat("ratio", .{ .v = &self.camera.ratio, .min = 0.5, .max = 2.0 });
    }
    imgui.end();
    imgui.backend.draw();

    self.gfx.swapBuffers();
    return true;
}

const Self = @This();
const Gfx = @import("Gfx.zig");

const gl = @import("zopengl").bindings;
const imgui = @import("zgui");
const std = @import("std");
const log = @import("log");
