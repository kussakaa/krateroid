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
const Text = @import("gui/Text.zig");
const Slider = @import("gui/Slider.zig");

const Event = union(enum) {
    none,
    button: union(enum) {
        focus: u32,
        unfocus: u32,
        press: u32,
        unpress: u32,
    },
    slider: union(enum) {
        value: struct {
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
pub var sliders: Array(Slider) = undefined;
pub var texts: Array(Text) = undefined;

pub const cursor = struct {
    var pos: Pos = .{ 0, 0 };
    var is_press: bool = false;

    pub fn setPos(p: Pos) void {
        pos = p;
        for (buttons.items) |*item| {
            if (item.menu.show and item.alignment.transform(item.rect.scale(scale), window.size).isAroundPoint(pos)) {
                if (item.state == .empty) events.push(.{ .button = .{ .focus = item.id } });
                if (is_press) {
                    item.state = .press;
                } else {
                    item.state = .focus;
                }
            } else {
                if (item.state != .empty) events.push(.{ .button = .{ .unfocus = item.id } });
                item.state = .empty;
            }
        }

        for (sliders.items) |*item| {
            var itemrect = item.rect;
            itemrect.min[0] += 2;
            itemrect.max[0] -= 3;
            itemrect.max[1] -= 1;
            const vprect = item.alignment.transform(itemrect.scale(scale), window.size);
            const vprectwidth: f32 = @floatFromInt(vprect.size()[0]);
            if (is_press and item.menu.show and vprect.isAroundPoint(pos)) {
                const value = @as(f32, @floatFromInt(pos[0] - vprect.min[0])) / vprectwidth;
                item.value = value;
                events.push(.{ .slider = .{ .value = .{
                    .id = item.id,
                    .data = value,
                } } });
            }
        }
    }

    pub fn press() void {
        is_press = true;
        for (buttons.items) |*item| {
            if (item.menu.show and item.alignment.transform(item.rect.scale(scale), window.size).isAroundPoint(pos)) {
                item.state = .press;
                events.push(.{ .button = .{ .press = item.id } });
            } else {
                item.state = .empty;
            }
        }

        for (sliders.items) |*item| {
            var itemrect = item.rect;
            itemrect.min[0] += 2;
            itemrect.max[0] -= 3;
            itemrect.max[1] -= 1;
            const vprect = item.alignment.transform(itemrect.scale(scale), window.size);
            const vprectwidth: f32 = @floatFromInt(vprect.size()[0]);
            if (is_press and item.menu.show and vprect.isAroundPoint(pos)) {
                const value = @as(f32, @floatFromInt(pos[0] - vprect.min[0])) / vprectwidth;
                item.value = value;
                events.push(.{ .slider = .{ .value = .{
                    .id = item.id,
                    .data = value,
                } } });
            }
        }
    }

    pub fn unpress() void {
        is_press = false;
        for (buttons.items) |*item| {
            if (item.menu.show and item.alignment.transform(item.rect.scale(scale), window.size).isAroundPoint(pos)) {
                item.state = .focus;
                events.push(.{ .button = .{ .unpress = item.id } });
            } else {
                item.state = .empty;
            }
        }
    }
};

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
}) !*const Panel {
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
}) !*const Button {
    try buttons.append(_allocator, Button{
        .menu = info.menu,
        .id = @intCast(buttons.items.len),
        .rect = info.rect,
        .alignment = info.alignment,
    });
    return &buttons.items[buttons.items.len - 1];
}

pub fn slider(info: struct {
    menu: *const Menu,
    rect: Rect,
    alignment: Alignment = .{},
    steps: i32 = 0,
    value: f32 = 0.5,
}) !*const Slider {
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

    const t = Text{
        .menu = info.menu,
        .data = data,
        .rect = .{ .min = itempos, .max = itempos + itemsize },
        .alignment = info.alignment,
        .usage = info.usage,
    };

    try texts.append(_allocator, t);
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
