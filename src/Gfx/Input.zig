allocator: Allocator,
keys: []bool,
frames: []u32,
frame: u32,

pub fn init(allocator: Allocator, window: Window, _: Config) anyerror!Input {
    var keys = try allocator.alloc(bool, 512);
    var frames = try allocator.alloc(u32, 512);
    @memset(keys[0..], false);
    @memset(frames[0..], 0);

    _ = window.handle.setKeyCallback(keyCallback);

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
    self.frame += 1;
    glfw.pollEvents();
}

pub fn isPressed(self: Input, key: glfw.Key) bool {
    const key_id: usize = @intCast(@intFromEnum(key));
    return (self.keys[key_id]);
}

pub fn isJustPressed(self: Input, key: glfw.Key) bool {
    const key_id: usize = @intCast(@intFromEnum(key));
    return if (self.frames[key_id] == self.frame) self.keys[key_id] else false;
}

fn keyCallback(window: *glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) callconv(.C) void {
    _ = scancode;
    _ = mods;

    const input = window.getUserPointer(Input).?;
    const key_id: usize = @intCast(@intFromEnum(key));
    if (action == .press) {
        input.keys[key_id] = true;
        input.frames[key_id] = input.frame;
    } else if (action == .release) {
        input.keys[key_id] = false;
        input.frames[key_id] = input.frame;
    }
}

const Input = @This();

pub const Config = struct {};

const Window = @import("Window.zig");

const Allocator = std.mem.Allocator;

const std = @import("std");
const glfw = @import("zglfw");
const log = @import("log");
