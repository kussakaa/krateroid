const std = @import("std");
const log = std.log.scoped(.gui);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;
const window = @import("window.zig");

const Pos = @Vector(2, i32);
const Size = @Vector(2, i32);
const Rect = @import("gui/Rect.zig");
const Alignment = @import("gui/Alignment.zig");
const Text = @import("gui/Text.zig");
const Button = @import("gui/Button.zig");

const Event = union(enum) {
    none,
    button: union(enum) {
        press: u32,
        unpress: u32,
    },
};

var _allocator: Allocator = undefined;
pub const font = @import("gui/font.zig");
pub var scale: i32 = undefined;
pub var texts: Array(Text) = undefined;
pub var buttons: Array(Button) = undefined;
pub const cursor = struct {
    var _pos: Pos = .{ 0, 0 };
    var _press: bool = false;

    pub fn pos(p: Pos) void {
        _pos = p;
        for (buttons.items, 0..) |b, i| {
            if (b.alignment.transform(b.rect.scale(scale), window.size).isAroundPoint(_pos)) {
                if (_press) {
                    buttons.items[i].state = .press;
                } else {
                    buttons.items[i].state = .focus;
                }
            } else {
                buttons.items[i].state = .empty;
            }
        }
    }

    pub fn press() void {
        _press = true;
        for (buttons.items, 0..) |b, i| {
            if (b.alignment.transform(b.rect.scale(scale), window.size).isAroundPoint(_pos)) {
                buttons.items[i].state = .press;
                pushEvent(Event{ .button = .{ .press = @intCast(i) } });
            } else {
                buttons.items[i].state = .empty;
            }
        }
    }

    pub fn unpress() void {
        _press = false;
        for (buttons.items, 0..) |b, i| {
            if (b.alignment.transform(b.rect.scale(scale), window.size).isAroundPoint(_pos)) {
                buttons.items[i].state = .focus;
                pushEvent(Event{ .button = .{ .unpress = @intCast(i) } });
            } else {
                buttons.items[i].state = .empty;
            }
        }
    }
};
const events = struct {
    var len: usize = 0;
    var items: [16]Event = undefined;
};

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    scale: i32 = 3,
}) !void {
    _allocator = info.allocator;
    scale = info.scale;
    font.init();
    texts = try Array(Text).initCapacity(_allocator, 32);
    buttons = try Array(Button).initCapacity(_allocator, 32);

    for (0..events.items.len) |i| {
        events.items[i] = .none;
    }
}

pub fn deinit() void {
    texts.deinit(_allocator);
    buttons.deinit(_allocator);
}

pub fn button(info: struct {
    text: []const u16,
    rect: Rect,
    alignment: Alignment = .{},
}) !u32 {
    const b = Button{
        .rect = info.rect,
        .alignment = info.alignment,
    };
    const bs = info.rect.size();
    const ts = calcTextSize(info.text);
    const tp = b.rect.min + Pos{ @divTrunc(bs[0] - ts[0], 2), @divTrunc(bs[1] - ts[1], 2) };
    const t = Text{
        .data = info.text,
        .rect = .{ .min = tp, .max = tp + ts },
        .alignment = info.alignment,
        .usage = .static,
    };
    try buttons.append(_allocator, b);
    try texts.append(_allocator, t);
    return @intCast(buttons.items.len - 1);
}

pub fn text(info: struct {
    data: []const u16,
    pos: Pos,
    alignment: Alignment = .{},
    usage: Text.Usage = .static,
}) !u32 {
    const size = calcTextSize(info.data);
    const t = Text{
        .data = info.data,
        .rect = .{ .min = info.pos, .max = info.pos + size },
        .alignment = info.alignment,
        .usage = info.usage,
    };
    try texts.append(_allocator, t);
    return @intCast(texts.items.len - 1);
}

fn calcTextSize(data: []const u16) Size {
    var width: i32 = 0;
    for (data) |c| {
        width += font.chars[c].width + 1;
    }
    width -= 1;
    return .{ width, 8 };
}

fn pushEvent(event: Event) void {
    if (events.len < events.items.len) {
        events.items[events.len] = event;
        events.len += 1;
    }
}

pub fn pollEvent() Event {
    const e = events.items[0];
    if (events.len != 0) {
        for (0..events.len) |i| {
            events.items[i] = events.items[i + 1];
        }
        events.len -= 1;
    }
    return e;
}
