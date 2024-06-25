allocator: mem.Allocator,

const Config = struct {
    allocator: mem.Allocator,
};

pub fn init(config: Config) mem.Allocator.Error!Drawer {
    return .{
        .allocator = config.allocator,
    };
}

pub fn deinit(self: *Drawer) void {
    self.* = undefined;
}

const Drawer = @This();

const Camera = @import("Camera.zig");
const Window = @import("Window.zig");
const World = @import("World.zig");

const std = @import("std");
const mem = std.mem;
const log = std.log.scoped(.drawer);

const gl = @import("zopengl").gl;
const zm = @import("zmath");
