gfx: Gfx,
context: *Context,
allocator: Allocator,

pub const Config = struct {
    gfx: Gfx,
    camera: Gfx.Camera.Config,
};

pub fn init(allocator: Allocator, config: Config) !Self {
    const gfx = config.gfx;
    const context = try allocator.create(Context);
    context.* = .{
        .camera = Gfx.Camera.init(config.camera),
        .world = .{
            .program = try Gfx.Program.init(allocator, .{ .name = "world" }),
        },
    };

    log.succes(.init, "DRAWER", .{});

    return .{
        .allocator = allocator,
        .gfx = gfx,
        .context = context,
    };
}

pub fn deinit(self: Self) void {
    self.context.world.program.deinit();
    self.allocator.destroy(self.context);
}

pub fn draw(self: Self) bool {
    self.gfx.clear();

    // WORLD
    //if (self.world) |_| {}

    // GUi
    //if (self.gui) |_| {}

    // IMGUI
    const fb_size = self.gfx.window.handle.getFramebufferSize();
    imgui.backend.newFrame(@intCast(fb_size[0]), @intCast(fb_size[1]));

    if (imgui.begin("Camera", .{})) {
        _ = imgui.sliderFloat4("pos", .{ .v = &self.context.camera.pos, .min = 0.0, .max = 32.0 });
        _ = imgui.sliderFloat4("rot", .{ .v = &self.context.camera.rot, .min = 0.0, .max = std.math.pi * 2 });
        _ = imgui.sliderFloat("scale", .{ .v = &self.context.camera.scale, .min = 0.1, .max = 32.0 });
        _ = imgui.sliderFloat("ratio", .{ .v = &self.context.camera.ratio, .min = 0.5, .max = 2.0 });
    }
    imgui.end();
    imgui.backend.draw();

    self.gfx.swapBuffers();
    return true;
}

const Context = struct {
    camera: Gfx.Camera,
    world: struct {
        program: Gfx.Program,
    },
};

const Self = @This();
const Gfx = @import("Gfx.zig");
const Allocator = std.mem.Allocator;

const gl = @import("zopengl").bindings;
const imgui = @import("zgui");
const std = @import("std");
const log = @import("log");
