const sdl = @import("sdl.zig");

pub const Point = @Vector(2, i32);

pub const Event = union(enum) {
    quit,
    keyboard_key_down: u32,
    keyboard_key_up: u32,
    mouse_button_down: u32,
    mouse_button_up: u32,
    mouse_motion: Point,
    window_size: Point,
    none,
};

pub const Keyboard = struct {
    pub const Key = u32;
    keys: [512]bool = [1]bool{false} ** 512,
};

pub const Mouse = struct {
    pub const Button = struct {
        const Code = u32;
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
            .keyboard_key_down => |key| self.keyboard.keys[@intCast(key)] = true,
            .keyboard_key_up => |key| self.keyboard.keys[@intCast(key)] = false,
            .mouse_button_down => |button| self.mouse.buttons[@intCast(button)] = true,
            .mouse_button_up => |button| self.mouse.buttons[@intCast(button)] = false,
            .mouse_motion => |pos| self.cursor.pos = pos,
            .window_size => |size| self.viewport.size = size,
            else => {},
        }
    }
};
