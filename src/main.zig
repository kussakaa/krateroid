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

    try data.init(.{});
    defer data.deinit();

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
        .hidden = true,
    });

    // Y
    var y_axis = try world.line(.{
        .p1 = camera.pos + Vec{ 0.0, 0.0, 0.0, 1.0 },
        .p2 = camera.pos + Vec{ 0.0, 1.0, 0.0, 1.0 },
        .color = .{ 0.5, 1.0, 0.5, 1.0 },
        .hidden = true,
    });

    // Z
    var z_axis = try world.line(.{
        .p1 = camera.pos + Vec{ 0.0, 0.0, 0.0, 1.0 },
        .p2 = camera.pos + Vec{ 0.0, 0.0, 1.0, 1.0 },
        .color = .{ 0.5, 0.5, 1.0, 1.0 },
        .hidden = true,
    });

    _ = try world.chunk(.{
        .pos = .{ 0, 0 },
    });

    try gui.init(.{ .allocator = allocator, .scale = 3 });
    defer gui.deinit();

    var menu_main = try gui.menu(.{ .hidden = false });
    const button_play = try gui.button(.{
        .text = W("<play>"),
        .rect = .{ .min = .{ -32, -25 }, .max = .{ 32, -9 } },
        .alignment = .{ .v = .center, .h = .center },
        .menu = menu_main,
    });
    _ = try gui.button(.{
        .text = W("<settings>"),
        .rect = .{ .min = .{ -32, -8 }, .max = .{ 32, 8 } },
        .alignment = .{ .v = .center, .h = .center },
        .menu = menu_main,
    });
    const button_exit = try gui.button(.{
        .text = W("<exit>"),
        .rect = .{ .min = .{ -32, 9 }, .max = .{ 32, 25 } },
        .alignment = .{ .v = .center, .h = .center },
        .menu = menu_main,
    });

    //var settings_menu = try gui.menu(.{ .hidden = true });

    // F3

    var menu_info = try gui.menu(.{
        .hidden = true,
    });
    _ = try gui.text(.{
        .data = W("krateroid alpha"),
        .pos = .{ 2, 1 },
        .menu = menu_info,
    });
    _ = try gui.text(.{
        .data = W("fps:"),
        .pos = .{ 2, 9 },
        .menu = menu_info,
    });
    var fps_str = [1]u16{'0'} ** 6;
    _ = try gui.text(.{
        .data = &fps_str,
        .pos = .{ 16, 9 },
        .usage = .dynamic,
        .menu = menu_info,
    });
    _ = try gui.text(.{
        .data = W("github.com/kussakaa/krateroid"),
        .pos = .{ 2, -8 },
        .alignment = .{ .v = .bottom },
        .menu = menu_info,
    });

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
                        if (id == .escape) menu_main.hidden = !menu_main.hidden;
                        if (id == .f3) {
                            menu_info.hidden = !menu_info.hidden;
                            x_axis.hidden = !x_axis.hidden;
                            y_axis.hidden = !y_axis.hidden;
                            z_axis.hidden = !z_axis.hidden;
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

                        if (is_camera_move and menu_main.hidden) {
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

                        if (is_camera_rotate and menu_main.hidden) {
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
                        if (menu_main.hidden) {
                            camera.scale = camera.scale * (1.0 - @as(f32, @floatFromInt(scroll)) * 0.1);
                        }
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
            switch (gui.pollEvent()) {
                .none => break :guiproc,
                .button => |b| switch (b) {
                    .press => |_| {
                        try audio_engine.playSound("data/sound/press.wav", null);
                    },
                    .unpress => |id| {
                        if (id == button_exit.id) break :loop;
                        if (id == button_play.id) menu_main.hidden = true;
                    },
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
