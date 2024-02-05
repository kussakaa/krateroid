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
const Text = @import("gui/Text.zig");
const Button = @import("gui/Button.zig");

const Event = union(enum) {
    none,
    button: union(enum) {
        focus: u32,
        unfocus: u32,
        press: u32,
        unpress: u32,
    },
};
pub const font = @import("gui/font.zig");

var allocator: Allocator = undefined;
pub var scale: i32 = undefined;
pub var menus: Array(Menu) = undefined;
pub var texts: Array(Text) = undefined;
pub var buttons: Array(Button) = undefined;

pub const cursor = struct {
    var pos: Pos = .{ 0, 0 };
    var is_press: bool = false;

    pub fn setPos(p: Pos) void {
        pos = p;
        for (buttons.items, 0..) |b, i| {
            if (b.alignment.transform(b.rect.scale(scale), window.size).isAroundPoint(pos) and b.menu.show) {
                if (buttons.items[i].state == .empty) events.push(.{ .button = .{ .focus = buttons.items[i].id } });
                if (is_press) {
                    buttons.items[i].state = .press;
                } else {
                    buttons.items[i].state = .focus;
                }
            } else {
                if (buttons.items[i].state != .empty) events.push(.{ .button = .{ .unfocus = buttons.items[i].id } });
                buttons.items[i].state = .empty;
            }
        }
    }

    pub fn press() void {
        is_press = true;
        for (buttons.items, 0..) |b, i| {
            if (b.alignment.transform(b.rect.scale(scale), window.size).isAroundPoint(pos) and b.menu.show) {
                buttons.items[i].state = .press;
                events.push(.{ .button = .{ .press = buttons.items[i].id } });
            } else {
                buttons.items[i].state = .empty;
            }
        }
    }

    pub fn unpress() void {
        is_press = false;
        for (buttons.items, 0..) |b, i| {
            if (b.alignment.transform(b.rect.scale(scale), window.size).isAroundPoint(pos) and b.menu.show) {
                buttons.items[i].state = .focus;
                events.push(.{ .button = .{ .unpress = buttons.items[i].id } });
            } else {
                buttons.items[i].state = .empty;
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
    allocator = info.allocator;
    scale = info.scale;
    font.init();
    texts = try Array(Text).initCapacity(allocator, 32);
    buttons = try Array(Button).initCapacity(allocator, 32);

    for (0..events.items.len) |i| {
        events.items[i] = .none;
    }
}

pub fn deinit() void {
    texts.deinit(allocator);
    buttons.deinit(allocator);
    menus.deinit(allocator);
}

pub fn menu(info: struct {
    show: bool = true,
}) !*Menu {
    const m = Menu{
        .id = @intCast(menus.items.len),
        .show = info.show,
    };
    try menus.append(allocator, m);
    return &menus.items[menus.items.len - 1];
}

pub fn button(info: struct {
    rect: Rect,
    alignment: Alignment = .{},
    menu: *const Menu,
}) !*const Button {
    const b = Button{
        .id = @intCast(buttons.items.len),
        .rect = info.rect,
        .alignment = info.alignment,
        .menu = info.menu,
    };
    try buttons.append(allocator, b);
    return &buttons.items[buttons.items.len - 1];
}

pub fn text(data: []const u16, info: struct {
    pos: Pos,
    alignment: Alignment = .{},
    centered: bool = false,
    usage: Text.Usage = .static,
    menu: *Menu,
}) !*Text {
    const ts = calcTextSize(data);
    const tp = if (info.centered)
        info.pos - Pos{ @divTrunc(ts[0], 2), @divTrunc(ts[1], 2) }
    else
        info.pos;
    const t = Text{
        .data = data,
        .rect = .{ .min = tp, .max = tp + ts },
        .alignment = info.alignment,
        .usage = info.usage,
        .menu = info.menu,
    };
    try texts.append(allocator, t);
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
