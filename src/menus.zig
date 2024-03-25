const std = @import("std");
const W = std.unicode.utf8ToUtf16LeStringLiteral;
const gui = @import("gui.zig");
const config = @import("config.zig");
const window = @import("window.zig");
const drawer = @import("drawer.zig");

pub const main = struct {
    pub var id: gui.Menu.Id = undefined;
    pub const button = struct {
        pub var play: gui.Button.Id = undefined;
        pub var settings: gui.Button.Id = undefined;
        pub var exit: gui.Button.Id = undefined;
    };
};

pub const settings = struct {
    pub var id: gui.Menu.Id = undefined;
    pub const switcher = struct {
        pub var show_info: gui.Switcher.Id = undefined;
        pub var show_grid: gui.Switcher.Id = undefined;
    };
    pub const slider = struct {
        pub var bg_r: gui.Slider.Id = undefined;
        pub var bg_g: gui.Slider.Id = undefined;
        pub var bg_b: gui.Slider.Id = undefined;
    };
};

pub const info = struct {
    pub var id: gui.Menu.Id = undefined;
    pub var fps_str_buffer = [1]u16{'0'} ** 6;
};

pub fn init() !void {
    main.id = try gui.menu.init(.{
        .show = true,
    });

    _ = try gui.panel.init(.{
        .menu = main.id,
        .rect = .{ .min = .{ -36, -46 }, .max = .{ 36, -30 } },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text.init(W("-<main>-"), .{
        .menu = main.id,
        .pos = .{ 0, -38 },
        .alignment = .{ .v = .center, .h = .center },
        .centered = true,
    });

    _ = try gui.panel.init(.{
        .menu = main.id,
        .rect = .{ .min = .{ -36, -29 }, .max = .{ 36, 29 } },
        .alignment = .{ .v = .center, .h = .center },
    });

    main.button.play = try gui.button.init(.{
        .menu = main.id,
        .rect = .{ .min = .{ -32, -25 }, .max = .{ 32, -9 } },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text.init(W("<play>"), .{
        .menu = main.id,
        .pos = .{ 0, -17 },
        .alignment = .{ .v = .center, .h = .center },
        .centered = true,
    });

    main.button.settings = try gui.button.init(.{
        .menu = main.id,
        .rect = .{ .min = .{ -32, -8 }, .max = .{ 32, 8 } },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text.init(W("<settings>"), .{
        .menu = main.id,
        .pos = .{ 0, 0 },
        .alignment = .{ .v = .center, .h = .center },
        .centered = true,
    });

    main.button.exit = try gui.button.init(.{
        .menu = main.id,
        .rect = .{ .min = .{ -32, 9 }, .max = .{ 32, 25 } },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text.init(W("<exit>"), .{
        .menu = main.id,
        .pos = .{ 0, 17 },
        .alignment = .{ .v = .center, .h = .center },
        .centered = true,
    });

    settings.id = try gui.menu.init(.{
        .show = false,
    });

    _ = try gui.panel.init(.{
        .menu = settings.id,
        .rect = .{ .min = .{ 38, -46 }, .max = .{ 138, -30 } },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text.init(W("-<settings>-"), .{
        .menu = settings.id,
        .pos = .{ 88, -38 },
        .alignment = .{ .v = .center, .h = .center },
        .centered = true,
    });

    _ = try gui.panel.init(.{
        .menu = settings.id,
        .rect = .{ .min = .{ 38, -29 }, .max = .{ 138, 29 } },
        .alignment = .{ .v = .center, .h = .center },
    });

    _ = try gui.text.init(W("info"), .{
        .menu = settings.id,
        .pos = .{ 42, -25 },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text.init(W("[f3]"), .{
        .menu = settings.id,
        .pos = .{ 107, -25 },
        .alignment = .{ .v = .center, .h = .center },
    });
    settings.switcher.show_info = try gui.switcher.init(.{
        .menu = settings.id,
        .pos = .{ 122, -25 },
        .alignment = .{ .v = .center, .h = .center },
        .status = config.debug.show_info,
    });

    _ = try gui.text.init(W("grid"), .{
        .menu = settings.id,
        .pos = .{ 42, -17 },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text.init(W("[f5]"), .{
        .menu = settings.id,
        .pos = .{ 107, -17 },
        .alignment = .{ .v = .center, .h = .center },
    });
    settings.switcher.show_grid = try gui.switcher.init(.{
        .menu = settings.id,
        .pos = .{ 122, -17 },
        .alignment = .{ .v = .center, .h = .center },
        .status = config.debug.show_grid,
    });

    _ = try gui.text.init(W("background color"), .{
        .menu = settings.id,
        .pos = .{ 42, -8 },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text.init(W("r"), .{
        .menu = settings.id,
        .pos = .{ 42, 0 },
        .alignment = .{ .v = .center, .h = .center },
    });
    settings.slider.bg_r = try gui.slider.init(.{
        .menu = settings.id,
        .rect = .{ .min = .{ 47, 0 }, .max = .{ 134, 8 } },
        .alignment = .{ .v = .center, .h = .center },
        .value = config.drawer.background.color[0],
    });
    _ = try gui.text.init(W("g"), .{
        .menu = settings.id,
        .pos = .{ 42, 8 },
        .alignment = .{ .v = .center, .h = .center },
    });
    settings.slider.bg_g = try gui.slider.init(.{
        .menu = settings.id,
        .rect = .{ .min = .{ 47, 8 }, .max = .{ 134, 16 } },
        .alignment = .{ .v = .center, .h = .center },
        .value = config.drawer.background.color[1],
    });
    _ = try gui.text.init(W("b"), .{
        .menu = settings.id,
        .pos = .{ 42, 16 },
        .alignment = .{ .v = .center, .h = .center },
    });
    settings.slider.bg_b = try gui.slider.init(.{
        .menu = settings.id,
        .rect = .{ .min = .{ 47, 16 }, .max = .{ 134, 24 } },
        .alignment = .{ .v = .center, .h = .center },
        .value = config.drawer.background.color[2],
    });

    info.id = try gui.menu.init(.{
        .show = config.debug.show_info,
    });
    _ = try gui.text.init(W("krateroid 0.0.1"), .{
        .menu = info.id,
        .pos = .{ 2, 1 },
    });
    _ = try gui.text.init(W("fps:"), .{
        .menu = info.id,
        .pos = .{ 2, 9 },
    });
    _ = try gui.text.init(&info.fps_str_buffer, .{
        .menu = info.id,
        .pos = .{ 16, 9 },
    });
    _ = try gui.text.init(W("https://github.com/kussakaa/krateroid"), .{
        .menu = info.id,
        .pos = .{ 2, -8 },
        .alignment = .{ .v = .bottom },
    });
}

pub fn update() !void {
    gui.switchers.items[settings.switcher.show_info].status = config.debug.show_info;
    gui.switchers.items[settings.switcher.show_grid].status = config.debug.show_grid;
    gui.menus.items[info.id].show = config.debug.show_info;

    var fps_str_buffer = [1]u8{'$'} ** 6;
    _ = try std.fmt.bufPrint(&fps_str_buffer, "{}", .{window.fps});
    _ = try std.unicode.utf8ToUtf16Le(&info.fps_str_buffer, &fps_str_buffer);
}
