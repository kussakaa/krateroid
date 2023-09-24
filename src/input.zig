const sdl = @import("sdl.zig");

pub const Point = @Vector(2, i32);

pub const Event = union(enum) {
    quit,
    key_down: Keyboard.Key,
    key_up: Keyboard.Key,
    mouse_button_down: Mouse.Button,
    mouse_button_up: Mouse.Button,
    mouse_motion: Point,
    window_size: Point,
    none,
};

pub const Keyboard = struct {
    pub const Key = i32;
    keys: [1024]bool = [1]bool{false} ** 1024,
};

pub const Mouse = struct {
    pub const Button = enum(usize) {
        left = 1,
        middle = 2,
        right = 3,
    };
    buttons: [9]bool = [1]bool{false} ** 9,
};

pub const State = struct {
    frame: u32 = 0,
    keyboard: Keyboard,
    mouse: Mouse,
    viewport: struct {
        size: Point = .{ 1200, 900 },
    },
    cursor: struct {
        pos: Point = .{ 0, 0 },
    },

    pub fn init() State {
        return State{
            .keyboard = .{},
            .mouse = .{},
            .viewport = .{},
            .cursor = .{},
        };
    }

    pub fn process(self: *State, event: Event) void {
        switch (event) {
            .mouse_button_down => |button| self.mouse.buttons[@intFromEnum(button)] = true,
            .mouse_button_up => |button| self.mouse.buttons[@intFromEnum(button)] = false,
            .mouse_motion => |pos| self.cursor.pos = .{ pos[0], self.viewport.size[1] - pos[1] },
            .window_size => |size| self.viewport.size = size,
            else => {},
        }
    }
};
