const std = @import("std");
const log = std.log.scoped(.Gui);
const Allocator = std.mem.Allocator;

const Point = @Vector(2, i32);
const Color = @Vector(4, f32);

pub const Rect = @import("Gui/Rect.zig");
pub const Alignment = @import("Gui/Alignment.zig");
pub const Font = @import("Gui/Font.zig");

pub const Text = @import("Gui/Text.zig");
pub const Button = @import("Gui/Button.zig");

const Gui = @This();

pub const Control = union(enum) {
    text: Text,
    button: Button,
};

controls: std.ArrayList(Control),
font: Font,

pub const InitInfo = struct {
    allocator: Allocator,
};

pub fn init(info: InitInfo) !Gui {
    return Gui{
        .controls = std.ArrayList(Control).init(info.allocator),
        .font = Font.init(),
    };
}

pub fn deinit(self: Gui) void {
    self.controls.deinit();
}

//pub fn text(self: *State, info: Text.InitInfo) !*Text {
//    var text_init_info: Text.InitInfo = info;
//    text_init_info.state = self.*;
//    const ctext = try Text.init(text_init_info); // инициализация константы текста
//    std.log.debug("init gui text = {}", .{ctext});
//    try self.controls.append(.{ .text = ctext });
//    return &self.controls.items[self.controls.items.len - 1].text;
//}

pub fn button(gui: *Gui, info: Button.InitInfo) !void {
    try gui.controls.append(.{ .button = try Button.init(gui.*, info) });
    log.debug("init {}", .{gui.controls.items[gui.controls.items.len - 1]});
}

//pub const InputSystem = struct {
//    pub fn process(state: *State, input_state: input.State) void {
//        for (state.*.controls.items) |*control| {
//            switch (control.*) {
//                .button => |*button| {
//                    if (button.alignment.transform(button.rect.scale(state.scale), state.vpsize).isAroundPoint(input_state.cursor.pos)) {
//                        button.state = .focus;
//
//                        if (button.state == .focus and input_state.mouse.buttons[1]) {
//                            button.state = .press;
//                        }
//                    } else {
//                        button.state = .empty;
//                    }
//                },
//                .text => {},
//            }
//        }
//    }
//};
//
//pub const Event = union(enum) {
//    press: u32,
//    unpress: u32,
//    none,
//};
//
//pub const EventSystem = struct {
//    pub fn process(state: State, input_state: input.State, event: input.Event) Event {
//        switch (event) {
//            .mouse_button_down => |mouse_button_code| if (mouse_button_code == 1) {
//                for (state.controls.items) |control| {
//                    switch (control) {
//                        .button => |button| {
//                            if (button.alignment.transform(
//                                button.rect.scale(state.scale),
//                                state.vpsize,
//                            ).isAroundPoint(input_state.cursor.pos)) {
//                                return .{ .press = button.id };
//                            }
//                        },
//                        else => {},
//                    }
//                }
//            },
//            .mouse_button_up => |mouse_button_code| if (mouse_button_code == 1) {
//                for (state.controls.items) |control| {
//                    switch (control) {
//                        .button => |button| {
//                            if (button.alignment.transform(
//                                button.rect.scale(state.scale),
//                                state.vpsize,
//                            ).isAroundPoint(input_state.cursor.pos)) {
//                                return .{ .unpress = button.id };
//                            }
//                        },
//                        else => {},
//                    }
//                }
//            },
//            else => {},
//        }
//        return .none;
//    }
//};
