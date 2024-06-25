allocator: mem.Allocator,
window: *Window,
camera: *Camera,
world: *World,

const Config = struct {
    allocator: mem.Allocator,
    window: *glfw.Window,
    camera: *Camera,
    world: *World,
};

pub fn init(config: Config) mem.Allocator.Error!Drawer {
    return .{
        .allocator = config.allocator,
        .window = config.window,
        .camera = config.camera,
        .world = config.world,
    };
}

pub fn deinit(self: *Drawer) void {
    self.* = undefined;
}

const Drawer = @This();

const Camera = @import("Camera.zig");
const Window = glfw.Window;
const World = @import("World.zig");

const std = @import("std");
const mem = std.mem;
const log = std.log.scoped(.drawer);

const glfw = @import("zglfw");
const gl = @import("zopengl").gl;
const zm = @import("zmath");
