const std = @import("std");
const zm = @import("zmath");
const gl = @import("zopengl");
const stb = @import("zstbi");
const audio = @import("zaudio");

const log = std.log.scoped(.main);
const pi = std.math.pi;
const W = std.unicode.utf8ToUtf16LeStringLiteral;

const Vec = zm.Vec;
const Mat = zm.Mat;

const window = @import("window.zig");
const input = @import("input.zig");
const data = @import("data.zig");
const camera = @import("camera.zig");
const world = @import("world.zig");
const gui = @import("gui.zig");
const drawer = @import("drawer.zig");

pub fn main() !void {
    std.debug.print("\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    stb.init(allocator);
    defer stb.deinit();

    audio.init(allocator);
    defer audio.deinit();

    const audio_engine = try audio.Engine.create(null);
    defer audio_engine.destroy();

    try audio_engine.setVolume(0.3);

    try window.init(.{ .title = "krateroid" });
    defer window.deinit();

    const cursor = struct {
        var pos: @Vector(2, i32) = .{ 0, 0 };
        var delta: @Vector(2, i32) = .{ 0, 0 };
    };

    var is_camera_move: bool = false;
    var is_camera_rotate: bool = false;
    camera.pos = .{ 15.0, 15.0, 0.0, 1.0 };
    camera.rot = .{ -pi / 6.0, 0.0, 0.0, 1.0 };
    camera.scale = 50.0;

    try world.init(.{ .allocator = allocator });
    defer world.deinit();

    // X
    var x_axis = try world.line(.{
        .p1 = camera.pos + Vec{ 0.0, 0.0, 0.0, 1.0 },
        .p2 = camera.pos + Vec{ 1.0, 0.0, 0.0, 1.0 },
        .color = .{ 1.0, 0.5, 0.5, 1.0 },
        .show = false,
    });

    // Y
    var y_axis = try world.line(.{
        .p1 = camera.pos + Vec{ 0.0, 0.0, 0.0, 1.0 },
        .p2 = camera.pos + Vec{ 0.0, 1.0, 0.0, 1.0 },
        .color = .{ 0.5, 1.0, 0.5, 1.0 },
        .show = false,
    });

    // Z
    var z_axis = try world.line(.{
        .p1 = camera.pos + Vec{ 0.0, 0.0, 0.0, 1.0 },
        .p2 = camera.pos + Vec{ 0.0, 0.0, 1.0, 1.0 },
        .color = .{ 0.5, 0.5, 1.0, 1.0 },
        .show = false,
    });

    _ = try world.chunk(.{
        .pos = .{ 0, 0 },
    });

    try gui.init(.{ .allocator = allocator, .scale = 3 });
    defer gui.deinit();

    var menu_main = try gui.menu(.{
        .show = true,
    });

    _ = try gui.panel(.{
        .menu = menu_main,
        .rect = .{ .min = .{ -36, -46 }, .max = .{ 36, -30 } },
        .alignment = .{ .v = .center, .h = .center },
    });

    _ = try gui.text(W("-<main menu>-"), .{
        .menu = menu_main,
        .pos = .{ 0, -38 },
        .alignment = .{ .v = .center, .h = .center },
        .centered = true,
    });

    _ = try gui.panel(.{
        .menu = menu_main,
        .rect = .{ .min = .{ -36, -29 }, .max = .{ 36, 29 } },
        .alignment = .{ .v = .center, .h = .center },
    });

    const button_play = try gui.button(.{
        .menu = menu_main,
        .rect = .{ .min = .{ -32, -25 }, .max = .{ 32, -9 } },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text(W("<play>"), .{
        .menu = menu_main,
        .pos = .{ 0, -17 },
        .alignment = .{ .v = .center, .h = .center },
        .centered = true,
    });

    const button_settings = try gui.button(.{
        .menu = menu_main,
        .rect = .{ .min = .{ -32, -8 }, .max = .{ 32, 8 } },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text(W("<settings>"), .{
        .menu = menu_main,
        .pos = .{ 0, 0 },
        .alignment = .{ .v = .center, .h = .center },
        .centered = true,
    });

    const button_exit = try gui.button(.{
        .menu = menu_main,
        .rect = .{ .min = .{ -32, 9 }, .max = .{ 32, 25 } },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text(W("<exit>"), .{
        .menu = menu_main,
        .pos = .{ 0, 17 },
        .alignment = .{ .v = .center, .h = .center },
        .centered = true,
    });

    var menu_settings = try gui.menu(.{
        .show = false,
    });
    const button_settings_close = try gui.button(.{
        .menu = menu_settings,
        .rect = .{ .min = .{ -32, 9 }, .max = .{ 32, 25 } },
        .alignment = .{ .v = .center, .h = .center },
    });
    _ = try gui.text(W("<close>"), .{
        .menu = menu_settings,
        .pos = .{ 0, 17 },
        .alignment = .{ .v = .center, .h = .center },
        .centered = true,
    });

    // F3

    var menu_info = try gui.menu(.{
        .show = false,
    });
    _ = try gui.text(W("krateroid alpha"), .{
        .menu = menu_info,
        .pos = .{ 2, 1 },
    });
    _ = try gui.text(W("fps:"), .{
        .menu = menu_info,
        .pos = .{ 2, 9 },
    });
    var fps_str = [1]u16{'0'} ** 6;
    _ = try gui.text(&fps_str, .{
        .menu = menu_info,
        .pos = .{ 16, 9 },
        .usage = .dynamic,
    });
    _ = try gui.text(W("https://github.com/kussakaa/krateroid"), .{
        .menu = menu_info,
        .pos = .{ 2, -8 },
        .alignment = .{ .v = .bottom },
    });

    try data.init(.{});
    defer data.deinit();

    try drawer.init(.{ .allocator = allocator });
    defer drawer.deinit();

    var is_debug_polygons = false;

    loop: while (true) {
        inputproc: while (true) {
            switch (input.pollEvent()) {
                .none => break :inputproc,
                .quit => break :loop,
                .key => |k| switch (k) {
                    .press => |id| {
                        if (id == .escape) {
                            menu_main.show = true;
                            menu_settings.show = false;
                        }
                        if (id == .f3) {
                            menu_info.show = !menu_info.show;
                            x_axis.show = !x_axis.show;
                            y_axis.show = !y_axis.show;
                            z_axis.show = !z_axis.show;
                        }
                        if (id == .f5) {
                            is_debug_polygons = !is_debug_polygons;
                            if (is_debug_polygons) {
                                drawer.polygon_mode = .line;
                            } else {
                                drawer.polygon_mode = .fill;
                            }
                        }
                        if (id == .f10) break :loop;
                        if (id == .kp_minus) gui.scale = @max(gui.scale - 1, 1);
                        if (id == .kp_plus) gui.scale = @min(gui.scale + 1, 8);
                    },
                    .unpress => |_| {},
                },
                .mouse => |m| switch (m) {
                    .button => |b| switch (b) {
                        .press => |id| {
                            if (id == 1) {
                                is_camera_move = true;
                                gui.cursor.press();
                            }
                            if (id == 3) {
                                is_camera_rotate = true;
                            }
                        },
                        .unpress => |id| {
                            if (id == 1) {
                                is_camera_move = false;
                                gui.cursor.unpress();
                            }
                            if (id == 3) {
                                is_camera_rotate = false;
                            }
                        },
                    },
                    .pos => |pos| {
                        cursor.delta = pos - cursor.pos;
                        cursor.pos = pos;

                        if (is_camera_move) {
                            const speed = 0.004;
                            const zsin = @sin(camera.rot[2]);
                            const zcos = @cos(camera.rot[2]);
                            const dtx = @as(f32, @floatFromInt(cursor.delta[0]));
                            const dty = @as(f32, @floatFromInt(cursor.delta[1]));
                            camera.pos += Vec{
                                (zsin * dty - zcos * dtx) * camera.scale * speed,
                                (zcos * dty + zsin * dtx) * camera.scale * speed,
                                0.0,
                                0.0,
                            };
                            x_axis.p1 = camera.pos + Vec{ 0.0, 0.0, 0.0, 1.0 };
                            x_axis.p2 = camera.pos + Vec{ 1.0, 0.0, 0.0, 1.0 };
                            y_axis.p1 = camera.pos + Vec{ 0.0, 0.0, 0.0, 1.0 };
                            y_axis.p2 = camera.pos + Vec{ 0.0, 1.0, 0.0, 1.0 };
                            z_axis.p1 = camera.pos + Vec{ 0.0, 0.0, 0.0, 1.0 };
                            z_axis.p2 = camera.pos + Vec{ 0.0, 0.0, 1.0, 1.0 };
                        }

                        if (is_camera_rotate) {
                            const speed = 0.005; // radians
                            const dtx = @as(f32, @floatFromInt(cursor.delta[0]));
                            const dty = @as(f32, @floatFromInt(cursor.delta[1]));
                            camera.rot += Vec{
                                dty * speed,
                                0.0,
                                dtx * speed,
                                0.0,
                            };
                        }

                        gui.cursor.setPos(pos);
                    },
                    .scroll => |scroll| {
                        camera.scale = camera.scale * (1.0 - @as(f32, @floatFromInt(scroll)) * 0.1);
                    },
                },
                .window => |w| switch (w) {
                    .size => |s| {
                        window.resize(s);
                    },
                },
                //else => {},
            }
        }

        guiproc: while (true) {
            const e = gui.pollEvent();
            //if (e != .none) log.info("gui event: {}", .{e});
            switch (e) {
                .none => break :guiproc,
                .button => |b| switch (b) {
                    .focus => |_| {
                        try audio_engine.playSound("data/sound/focus.wav", null);
                    },
                    .unfocus => |_| {},
                    .press => |id| {
                        try audio_engine.playSound("data/sound/press.wav", null);
                        if (id == button_play.id)
                            menu_main.show = false;
                        if (id == button_settings.id) {
                            menu_settings.show = true;
                            menu_main.show = false;
                        }
                        if (id == button_settings_close.id) {
                            menu_settings.show = false;
                            menu_main.show = true;
                        }
                        if (id == button_exit.id)
                            break :loop;
                    },
                    .unpress => |_| {},
                },
            }
        }

        camera.view = zm.identity();
        camera.view = zm.mul(camera.view, zm.translationV(-camera.pos));
        camera.view = zm.mul(camera.view, zm.rotationZ(camera.rot[2]));
        camera.view = zm.mul(camera.view, zm.rotationX(camera.rot[0]));
        const h = 1.0 / camera.scale;
        const v = 1.0 / camera.scale / window.ratio;
        camera.proj = Mat{
            .{ v, 0.0, 0.0, 0.0 },
            .{ 0.0, h, 0.0, 0.0 },
            .{ 0.0, 0.0, -0.00001, 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        };

        { // обновление fps счётчика
            var fps_str_buf = [1]u8{'$'} ** 6;
            _ = try std.fmt.bufPrint(&fps_str_buf, "{}", .{window.fps});
            _ = try std.unicode.utf8ToUtf16Le(&fps_str, &fps_str_buf);
        }

        window.clear(.{
            .color = .{ 0.0, 0.0, 0.0, 1.0 },
        });
        try drawer.draw();
        window.swap();
    }
}
