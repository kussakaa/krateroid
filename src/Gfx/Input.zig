allocator: Allocator,
keys: []bool,
frames: []u32,
frame: u32,

pub fn init(allocator: Allocator, _: Config) anyerror!Input {
    var keys = try allocator.alloc(bool, 512);
    var frames = try allocator.alloc(u32, 512);
    @memset(keys[0..], false);
    @memset(frames[0..], 0);

    log.succes("Initialized GFX Input", .{});

    return .{
        .allocator = allocator,
        .keys = keys,
        .frames = frames,
        .frame = 0,
    };
}

pub fn deinit(self: Input) void {
    self.allocator.free(self.keys);
    self.allocator.free(self.frames);
}

pub fn update(self: *Input) void {
    glfw.pollEvents();
    _ = self;
}

const Input = @This();

pub const Config = struct {};

const Window = @import("Window.zig");

const Allocator = std.mem.Allocator;

const std = @import("std");
const glfw = @import("zglfw");
const log = @import("log");
