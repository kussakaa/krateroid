//const std = @import("std");
//const log = std.log.scoped(.gui);
//const Allocator = std.mem.Allocator;
//const Array = std.ArrayListUnmanaged;
//const window = @import("window.zig");
//
//pub const Pos = @Vector(2, i32);
//pub const Size = @Vector(2, i32);
//pub const Rect = @import("gui/Rect.zig");
//pub const Color = @Vector(4, f32);
//pub const Alignment = @import("gui/Alignment.zig");
//pub const Menu = @import("gui/Menu.zig");
//pub const Panel = @import("gui/Panel.zig");
//pub const Button = @import("gui/Button.zig");
//pub const Switcher = @import("gui/Switcher.zig");
//pub const Slider = @import("gui/Slider.zig");
//pub const Text = @import("gui/Text.zig");
//pub const font = @import("gui/font.zig");
//
//var _allocator: Allocator = undefined;
//pub var scale: i32 = undefined;
//pub var menus: Array(Menu) = undefined;
//pub var panels: Array(Panel) = undefined;
//pub var buttons: Array(Button) = undefined;
//pub var switchers: Array(Switcher) = undefined;
//pub var sliders: Array(Slider) = undefined;
//pub var texts: Array(Text) = undefined;
//
//pub fn init(info: struct {
//    allocator: Allocator = std.heap.page_allocator,
//    scale: i32 = 3,
//}) !void {
//    _allocator = info.allocator;
//    scale = info.scale;
//    font.init();
//    menus = try Array(Menu).initCapacity(_allocator, 32);
//    panels = try Array(Panel).initCapacity(_allocator, 32);
//    buttons = try Array(Button).initCapacity(_allocator, 32);
//    switchers = try Array(Switcher).initCapacity(_allocator, 32);
//    sliders = try Array(Slider).initCapacity(_allocator, 32);
//    texts = try Array(Text).initCapacity(_allocator, 32);
//
//    for (0..events.items.len) |i| {
//        events.items[i] = .none;
//    }
//}
//
//pub fn deinit() void {
//    defer menus.deinit(_allocator);
//    defer panels.deinit(_allocator);
//    defer buttons.deinit(_allocator);
//    defer switchers.deinit(_allocator);
//    defer sliders.deinit(_allocator);
//    defer texts.deinit(_allocator);
//}
//
//pub const cursor = struct {
//    pub var pos: Pos = .{ 0, 0 };
//    pub var press: bool = false;
//};
//
//pub fn update() void {
//    { // BUTTONS
//        for (buttons.items) |*item| {
//            const vprect = item.alignment.transform(item.rect.scale(scale), window.size);
//            if (menus.items[item.menu].show and vprect.isAroundPoint(cursor.pos)) {
//                if (cursor.press) {
//                    if (item.state != .press) {
//                        if (item.state == .empty) events.push(.{ .button = .{ .focused = item.id } });
//                        events.push(.{ .button = .{ .pressed = item.id } });
//                    }
//                    item.state = .press;
//                } else {
//                    if (item.state == .press) events.push(.{ .button = .{ .unpressed = item.id } });
//                    if (item.state == .empty) events.push(.{ .button = .{ .focused = item.id } });
//                    item.state = .focus;
//                }
//            } else {
//                if (item.state != .empty) events.push(.{ .button = .{ .unfocused = item.id } });
//                item.state = .empty;
//            }
//        }
//    }
//    { // SWITCHERS
//        for (switchers.items) |*item| {
//            const itemrect = Rect{
//                .min = .{
//                    item.pos[0],
//                    item.pos[1],
//                },
//                .max = .{
//                    item.pos[0] + 12,
//                    item.pos[1] + 8,
//                },
//            };
//            const vprect = item.alignment.transform(itemrect.scale(scale), window.size);
//            if (menus.items[item.menu].show and vprect.isAroundPoint(cursor.pos)) {
//                if (cursor.press) {
//                    if (item.state != .press) {
//                        if (item.state == .empty) events.push(.{ .switcher = .{ .focused = item.id } });
//                        events.push(.{ .switcher = .{ .pressed = item.id } });
//                    }
//                    item.state = .press;
//                } else {
//                    if (item.state == .press) {
//                        events.push(.{ .switcher = .{ .unpressed = item.id } });
//                        item.status = !item.status;
//                        events.push(.{ .switcher = .{ .switched = .{ .id = item.id, .data = item.status } } });
//                    }
//                    if (item.state == .empty) events.push(.{ .switcher = .{ .focused = item.id } });
//                    item.state = .focus;
//                }
//            } else {
//                if (item.state != .empty) events.push(.{ .switcher = .{ .unfocused = item.id } });
//                item.state = .empty;
//            }
//        }
//    }
//    { // SLIDERS
//        for (sliders.items) |*item| { // sliders
//            const itemrect = Rect{
//                .min = .{
//                    item.rect.min[0] + 2,
//                    item.rect.min[1],
//                },
//                .max = .{
//                    item.rect.max[0] - 2,
//                    item.rect.max[1],
//                },
//            };
//            const vprect = item.alignment.transform(itemrect.scale(scale), window.size);
//            const vprectwidth: f32 = @floatFromInt(vprect.size()[0]);
//            if (menus.items[item.menu].show and vprect.isAroundPoint(cursor.pos)) {
//                if (cursor.press) {
//                    if (item.state != .press) {
//                        if (item.state == .empty) events.push(.{ .slider = .{ .focused = item.id } });
//                        events.push(.{ .slider = .{ .pressed = item.id } });
//                    }
//                    item.state = .press;
//                    const value = @as(f32, @floatFromInt(cursor.pos[0] - vprect.min[0])) / vprectwidth;
//                    item.value = value;
//                    events.push(.{ .slider = .{ .scrolled = .{
//                        .id = item.id,
//                        .data = value,
//                    } } });
//                } else {
//                    if (item.state == .press) events.push(.{ .slider = .{ .unpressed = item.id } });
//                    if (item.state == .empty) events.push(.{ .slider = .{ .focused = item.id } });
//                    item.state = .focus;
//                }
//            } else {
//                if (item.state != .empty) events.push(.{ .slider = .{ .unfocused = item.id } });
//                item.state = .empty;
//            }
//        }
//    }
//}
//
//const Event = union(enum) {
//    none,
//    button: union(enum) {
//        focused: Button.Id,
//        unfocused: Button.Id,
//        pressed: Button.Id,
//        unpressed: Button.Id,
//    },
//    switcher: union(enum) {
//        focused: Switcher.Id,
//        unfocused: Switcher.Id,
//        pressed: Switcher.Id,
//        unpressed: Switcher.Id,
//        switched: struct {
//            id: Switcher.Id,
//            data: bool,
//        },
//    },
//    slider: union(enum) {
//        focused: Slider.Id,
//        unfocused: Slider.Id,
//        pressed: Slider.Id,
//        unpressed: Slider.Id,
//        scrolled: struct {
//            id: Slider.Id,
//            data: f32,
//        },
//    },
//};
//
//pub var events = @import("util").Queue(16, Event, Event.none){};
//
//pub const menu = struct {
//    pub fn init(info: struct {
//        show: bool = true,
//    }) !Menu.Id {
//        try menus.append(_allocator, Menu{
//            .id = menus.items.len,
//            .show = info.show,
//        });
//        return menus.items.len - 1;
//    }
//};
//
//pub const panel = struct {
//    pub fn init(info: struct {
//        menu: Menu.Id,
//        rect: Rect,
//        alignment: Alignment = .{},
//    }) !Panel.Id {
//        try panels.append(_allocator, Panel{
//            .menu = info.menu,
//            .id = panels.items.len,
//            .rect = info.rect,
//            .alignment = info.alignment,
//        });
//        return panels.items.len - 1;
//    }
//};
//
//pub const button = struct {
//    pub fn init(info: struct {
//        menu: Menu.Id,
//        rect: Rect,
//        alignment: Alignment = .{},
//    }) !Button.Id {
//        try buttons.append(_allocator, Button{
//            .menu = info.menu,
//            .id = buttons.items.len,
//            .rect = info.rect,
//            .alignment = info.alignment,
//        });
//        return buttons.items.len - 1;
//    }
//};
//
//pub const switcher = struct {
//    pub fn init(info: struct {
//        menu: Menu.Id,
//        pos: Pos,
//        alignment: Alignment = .{},
//        status: bool = false,
//    }) !Switcher.Id {
//        try switchers.append(_allocator, Switcher{
//            .menu = info.menu,
//            .id = switchers.items.len,
//            .pos = info.pos,
//            .alignment = info.alignment,
//            .status = info.status,
//        });
//        return switchers.items.len - 1;
//    }
//};
//
//pub const slider = struct {
//    pub fn init(info: struct {
//        menu: Menu.Id,
//        rect: Rect,
//        alignment: Alignment = .{},
//        steps: i32 = 0,
//        value: f32 = 0.0,
//    }) !Slider.Id {
//        try sliders.append(_allocator, Slider{
//            .menu = info.menu,
//            .id = sliders.items.len,
//            .rect = info.rect,
//            .alignment = info.alignment,
//            .steps = info.steps,
//            .value = info.value,
//        });
//        return sliders.items.len - 1;
//    }
//};
//
//pub const text = struct {
//    pub var list: Array(Text) = undefined;
//    pub fn init(data: []const u16, info: struct {
//        menu: Menu.Id,
//        pos: Pos,
//        alignment: Alignment = .{},
//        centered: bool = false,
//    }) !Text.Id {
//        const itemsize = size(data);
//        const itempos = if (info.centered)
//            info.pos - Pos{ @divTrunc(itemsize[0], 2), @divTrunc(itemsize[1], 2) }
//        else
//            info.pos;
//
//        try texts.append(_allocator, Text{
//            .menu = info.menu,
//            .id = texts.items.len,
//            .data = data,
//            .rect = .{ .min = itempos, .max = itempos + itemsize },
//            .alignment = info.alignment,
//        });
//        return texts.items.len - 1;
//    }
//
//    fn size(data: []const u16) Size {
//        var width: i32 = 0;
//        for (data) |c| width += font.chars[c].width + 1;
//        width -= 1;
//        return .{ width, 8 };
//    }
//};
//
