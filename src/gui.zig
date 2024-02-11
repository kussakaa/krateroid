const std = @import("std");
const log = std.log.scoped(.gui);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;
const window = @import("window.zig");

const Pos = @Vector(2, i32);
const Size = @Vector(2, i32);
const Rect = @import("gui/Rect.zig");
const Alignment = @import("gui/Alignment.zig");
const Menu = @import("gui/Menu.zig");
const Panel = @import("gui/Panel.zig");
const Button = @import("gui/Button.zig");
const Switcher = @import("gui/Switcher.zig");
const Slider = @import("gui/Slider.zig");
const Text = @import("gui/Text.zig");

const Event = union(enum) {
    none,
    button: union(enum) {
        focused: u32,
        unfocused: u32,
        pressed: u32,
        unpressed: u32,
    },
    switcher: union(enum) {
        focused: u32,
        unfocused: u32,
        pressed: u32,
        unpressed: u32,
        switched: struct {
            id: u32,
            data: bool,
        },
    },
    slider: union(enum) {
        focused: u32,
        unfocused: u32,
        pressed: u32,
        unpressed: u32,
        scrolled: struct {
            id: u32,
            data: f32,
        },
    },
};

pub const font = @import("gui/font.zig");
var _allocator: Allocator = undefined;
pub var scale: i32 = undefined;
pub var menus: Array(Menu) = undefined;
pub var panels: Array(Panel) = undefined;
pub var buttons: Array(Button) = undefined;
pub var switchers: Array(Switcher) = undefined;
pub var sliders: Array(Slider) = undefined;
pub var texts: Array(Text) = undefined;

pub const cursor = struct {
    pub var pos: Pos = .{ 0, 0 };
    pub var press: bool = false;
};

pub fn update() void {
    { // BUTTONS
        for (buttons.items) |*item| {
            const vprect = item.alignment.transform(item.rect.scale(scale), window.size);
            if (item.menu.show and vprect.isAroundPoint(cursor.pos)) {
                if (cursor.press) {
                    if (item.state != .press) {
                        if (item.state == .empty) events.push(.{ .button = .{ .focused = item.id } });
                        events.push(.{ .button = .{ .pressed = item.id } });
                    }
                    item.state = .press;
                } else {
                    if (item.state == .press) events.push(.{ .button = .{ .unpressed = item.id } });
                    if (item.state == .empty) events.push(.{ .button = .{ .focused = item.id } });
                    item.state = .focus;
                }
            } else {
                if (item.state != .empty) events.push(.{ .button = .{ .unfocused = item.id } });
                item.state = .empty;
            }
        }
    }
    { // SWITCHERS
        for (switchers.items) |*item| {
            const itemrect = Rect{
                .min = .{
                    item.pos[0],
                    item.pos[1],
                },
                .max = .{
                    item.pos[0] + 12,
                    item.pos[1] + 8,
                },
            };
            const vprect = item.alignment.transform(itemrect.scale(scale), window.size);
            if (item.menu.show and vprect.isAroundPoint(cursor.pos)) {
                if (cursor.press) {
                    if (item.state != .press) {
                        if (item.state == .empty) events.push(.{ .switcher = .{ .focused = item.id } });
                        events.push(.{ .switcher = .{ .pressed = item.id } });
                    }
                    item.state = .press;
                } else {
                    if (item.state == .press) {
                        events.push(.{ .switcher = .{ .unpressed = item.id } });
                        item.status = !item.status;
                        events.push(.{ .switcher = .{ .switched = .{ .id = item.id, .data = item.status } } });
                    }
                    if (item.state == .empty) events.push(.{ .switcher = .{ .focused = item.id } });
                    item.state = .focus;
                }
            } else {
                if (item.state != .empty) events.push(.{ .switcher = .{ .unfocused = item.id } });
                item.state = .empty;
            }
        }
    }
    { // SLIDERS
        for (sliders.items) |*item| { // sliders
            const itemrect = Rect{
                .min = .{
                    item.rect.min[0] + 2,
                    item.rect.min[1],
                },
                .max = .{
                    item.rect.max[0] - 2,
                    item.rect.max[1],
                },
            };
            const vprect = item.alignment.transform(itemrect.scale(scale), window.size);
            const vprectwidth: f32 = @floatFromInt(vprect.size()[0]);
            if (item.menu.show and vprect.isAroundPoint(cursor.pos)) {
                if (cursor.press) {
                    if (item.state != .press) {
                        if (item.state == .empty) events.push(.{ .slider = .{ .focused = item.id } });
                        events.push(.{ .slider = .{ .pressed = item.id } });
                    }
                    item.state = .press;
                    const value = @as(f32, @floatFromInt(cursor.pos[0] - vprect.min[0])) / vprectwidth;
                    item.value = value;
                    events.push(.{ .slider = .{ .scrolled = .{
                        .id = item.id,
                        .data = value,
                    } } });
                } else {
                    if (item.state == .press) events.push(.{ .slider = .{ .unpressed = item.id } });
                    if (item.state == .empty) events.push(.{ .slider = .{ .focused = item.id } });
                    item.state = .focus;
                }
            } else {
                if (item.state != .empty) events.push(.{ .slider = .{ .unfocused = item.id } });
                item.state = .empty;
            }
        }
    }
}

const events = struct {
    var items: [16]Event = undefined;
    var current: usize = 0;
    var current_event: usize = 0;

    fn push(event: Event) void {
        items[current_event] = event;
        if (current_event < items.len - 1) {
            current_event += 1;
        } else {
            current_event = 0;
        }
    }

    fn pop() Event {
        if (current != current_event) {
            const e = items[current];
            if (current < items.len - 1) {
                current += 1;
            } else {
                current = 0;
            }
            return e;
        } else {
            return .none;
        }
    }
};

pub fn pollEvent() Event {
    return events.pop();
}

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    scale: i32 = 3,
}) !void {
    _allocator = info.allocator;
    scale = info.scale;
    font.init();
    menus = try Array(Menu).initCapacity(_allocator, 32);
    panels = try Array(Panel).initCapacity(_allocator, 32);
    buttons = try Array(Button).initCapacity(_allocator, 32);
    switchers = try Array(Switcher).initCapacity(_allocator, 32);
    sliders = try Array(Slider).initCapacity(_allocator, 32);
    texts = try Array(Text).initCapacity(_allocator, 32);

    for (0..events.items.len) |i| {
        events.items[i] = .none;
    }
}

pub fn deinit() void {
    defer menus.deinit(_allocator);
    defer panels.deinit(_allocator);
    defer buttons.deinit(_allocator);
    defer switchers.deinit(_allocator);
    defer sliders.deinit(_allocator);
    defer texts.deinit(_allocator);
}

pub fn rect(x1: i32, y1: i32, x2: i32, y2: i32) Rect {
    return Rect{
        .min = .{ x1, y1 },
        .max = .{ x2, y2 },
    };
}

pub fn menu(info: struct {
    show: bool = true,
}) !*Menu {
    try menus.append(_allocator, Menu{
        .id = @intCast(menus.items.len),
        .show = info.show,
    });
    return &menus.items[menus.items.len - 1];
}

pub fn panel(info: struct {
    menu: *const Menu,
    rect: Rect,
    alignment: Alignment = .{},
}) !*Panel {
    try panels.append(_allocator, Panel{
        .menu = info.menu,
        .rect = info.rect,
        .alignment = info.alignment,
    });
    return &panels.items[panels.items.len - 1];
}

pub fn button(info: struct {
    menu: *const Menu,
    rect: Rect,
    alignment: Alignment = .{},
}) !*Button {
    try buttons.append(_allocator, Button{
        .menu = info.menu,
        .id = @intCast(buttons.items.len),
        .rect = info.rect,
        .alignment = info.alignment,
    });
    return &buttons.items[buttons.items.len - 1];
}

pub fn switcher(info: struct {
    menu: *const Menu,
    pos: Pos,
    alignment: Alignment = .{},
    status: bool = false,
}) !*Switcher {
    try switchers.append(_allocator, Switcher{
        .menu = info.menu,
        .id = @intCast(switchers.items.len),
        .pos = info.pos,
        .alignment = info.alignment,
        .status = info.status,
    });
    return &switchers.items[switchers.items.len - 1];
}

pub fn slider(info: struct {
    menu: *const Menu,
    rect: Rect,
    alignment: Alignment = .{},
    steps: i32 = 0,
    value: f32 = 0.0,
}) !*Slider {
    try sliders.append(_allocator, Slider{
        .menu = info.menu,
        .id = @intCast(sliders.items.len),
        .rect = info.rect,
        .alignment = info.alignment,
        .steps = info.steps,
        .value = info.value,
    });
    return &sliders.items[sliders.items.len - 1];
}

pub fn text(data: []const u16, info: struct {
    menu: *const Menu,
    pos: Pos,
    alignment: Alignment = .{},
    centered: bool = false,
    usage: Text.Usage = .static,
}) !*Text {
    const itemsize = calcTextSize(data);
    const itempos = if (info.centered)
        info.pos - Pos{ @divTrunc(itemsize[0], 2), @divTrunc(itemsize[1], 2) }
    else
        info.pos;

    try texts.append(_allocator, Text{
        .menu = info.menu,
        .data = data,
        .rect = .{ .min = itempos, .max = itempos + itemsize },
        .alignment = info.alignment,
        .usage = info.usage,
    });
    return &texts.items[texts.items.len - 1];
}

fn calcTextSize(data: []const u16) Size {
    var width: i32 = 0;
    for (data) |c| {
        width += font.chars[c].width + 1;
    }
    width -= 1;
    return .{ width, 8 };
}
