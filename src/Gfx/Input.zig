allocator: Allocator,
context: *Context,

pub fn init(allocator: Allocator, window: Window, _: Config) anyerror!Input {
    const context = try allocator.create(Context);
    context.frame = 0;
    @memset(context.frames[0..], 0);
    @memset(context.keys[0..], false);

    window.handle.setUserPointer(context);

    _ = window.handle.setKeyCallback(keyCallback);

    log.succes("Initialized GFX Input", .{});

    return .{
        .allocator = allocator,
        .context = context,
    };
}

pub fn deinit(self: Input) void {
    self.allocator.destroy(self.context);
}

pub fn update(self: *Input) void {
    self.context.frame += 1;
    glfw.pollEvents();
}

pub fn isPressed(self: Input, key: glfw.Key) bool {
    const key_id: usize = @intCast(@intFromEnum(key));
    return (self.keys[key_id]);
}

pub fn isJustPressed(self: Input, key: glfw.Key) bool {
    const key_id: usize = @intCast(@intFromEnum(key));
    return if (self.context.frames[key_id] == self.context.frame)
        self.context.keys[key_id]
    else
        false;
}

fn keyCallback(window: *glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) callconv(.C) void {
    _ = scancode;
    _ = mods;

    const context = window.getUserPointer(Context).?;
    const key_id: usize = @intCast(@intFromEnum(key));
    if (action == .press) {
        context.keys[key_id] = true;
        context.frames[key_id] = context.frame;
    } else if (action == .release) {
        context.keys[key_id] = false;
        context.frames[key_id] = context.frame;
    }
}

pub const Config = struct {};

const Input = @This();
const Window = @import("Window.zig");
const Allocator = std.mem.Allocator;
const Context = struct {
    frame: u32,
    frames: [512]u32,
    keys: [512]bool,
};

const std = @import("std");
const glfw = @import("zglfw");
const log = @import("log");
