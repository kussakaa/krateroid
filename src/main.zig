const std = @import("std");
const log = std.log.scoped(.main);
const pi = std.math.pi;
const W = std.unicode.utf8ToUtf16LeStringLiteral;

const c = @import("c.zig");

const lm = @import("linmath.zig");
const Vec = lm.Vec;
const Mat = lm.Mat;

const window = @import("window.zig");
const input = @import("input.zig");
const camera = @import("camera.zig");
const world = @import("world.zig");
const gui = @import("gui.zig");
const drawer = @import("drawer.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    try window.init(.{ .title = "krateroid" });
    defer window.deinit();

    const cursor = struct {
        var pos: @Vector(2, i32) = .{ 0, 0 };
        var delta: @Vector(2, i32) = .{ 0, 0 };
    };
    var is_camera_move: bool = false;
    var is_camera_rotate: bool = false;
    camera.pos = .{ 15.0, 15.0, 0.0, 1.0 };
    camera.scale = 50.0;

    try world.init(.{ .allocator = allocator });
    defer world.deinit();

    _ = try world.chunk(.{
        .pos = .{ 0, 0 },
    });

    try gui.init(.{ .allocator = allocator, .scale = 3 });
    defer gui.deinit();

    var menu_main = try gui.menu(.{
        .hidden = true,
    });
    const button_play = try gui.button(.{
        .text = W("<play>"),
        .rect = .{ .min = .{ -32, -26 }, .max = .{ 32, -10 } },
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
        .rect = .{ .min = .{ -32, 10 }, .max = .{ 32, 26 } },
        .alignment = .{ .v = .center, .h = .center },
        .menu = menu_main,
    });

    // F3

    var menu_info = try gui.menu(.{
        .hidden = true,
    });
    _ = try gui.text(.{
        .data = W("krateroid build 2"),
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
        .data = W("gitlab.com/kussakaa/krateroid"),
        .pos = .{ 2, -8 },
        .alignment = .{ .v = .bottom },
        .menu = menu_info,
    });

    try drawer.init(.{ .allocator = allocator });
    defer drawer.deinit();

    loop: while (true) {
        inputproc: while (true) {
            switch (input.pollEvent()) {
                .none => break :inputproc,
                .quit => break :loop,
                .key => |k| switch (k) {
                    .press => |id| {
                        if (id == c.SDL_SCANCODE_ESCAPE) menu_main.hidden = !menu_main.hidden;
                        if (id == c.SDL_SCANCODE_F3) menu_info.hidden = !menu_info.hidden;
                        if (id == c.SDL_SCANCODE_F5) c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

                        if (id == c.SDL_SCANCODE_O) gui.scale = @max(gui.scale - 1, 1);
                        if (id == c.SDL_SCANCODE_P) gui.scale = @min(gui.scale + 1, 8);

                        if (id == c.SDL_SCANCODE_RIGHT) camera.rot[2] += pi / 4.0;
                        if (id == c.SDL_SCANCODE_LEFT) camera.rot[2] -= pi / 4.0;
                        if (id == c.SDL_SCANCODE_UP) camera.rot[0] += pi / 6.0;
                        if (id == c.SDL_SCANCODE_DOWN) camera.rot[0] -= pi / 6.0;
                    },
                    .unpress => |_| {},
                },
                .mouse => |m| switch (m) {
                    .button => |b| switch (b) {
                        .press => |id| {
                            if (id == 1) {
                                if (menu_main.hidden) is_camera_move = true;
                                gui.cursor.press();
                            }
                            if (id == 3) {
                                if (menu_main.hidden) is_camera_rotate = true;
                            }
                        },
                        .unpress => |id| {
                            if (id == 1) {
                                if (menu_main.hidden) is_camera_move = false;
                                gui.cursor.unpress();
                            }
                            if (id == 3) {
                                if (menu_main.hidden) is_camera_rotate = false;
                            }
                        },
                    },
                    .pos => |pos| {
                        cursor.delta = pos - cursor.pos;
                        cursor.pos = pos;

                        if (is_camera_move) {
                            const speed = 0.003;
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
                        }

                        if (is_camera_rotate) {
                            const speed = 0.0002; // radians
                            const dtx = @as(f32, @floatFromInt(cursor.delta[0]));
                            const dty = @as(f32, @floatFromInt(cursor.delta[1]));
                            camera.rot += Vec{
                                -dty * camera.scale * speed,
                                0.0,
                                dtx * camera.scale * speed,
                                0.0,
                            };
                        }

                        gui.cursor.setPos(pos);
                    },
                    .scroll => |scroll| camera.scale = camera.scale * (1.0 - @as(f32, @floatFromInt(scroll)) * 0.1),
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
                    .press => |_| {},
                    .unpress => |id| {
                        if (id == button_exit.id) break :loop;
                        if (id == button_play.id) menu_main.hidden = true;
                    },
                },
            }
        }

        camera.view = lm.identity(Mat);
        camera.view = lm.mul(camera.view, lm.rotateX(camera.rot[0]));
        camera.view = lm.mul(camera.view, lm.rotateZ(camera.rot[2]));
        camera.view = lm.mul(camera.view, lm.transform(camera.pos));
        camera.proj = lm.scale(.{ 1.0 / camera.scale / window.ratio, 1.0 / camera.scale, 0.0001, 1.0 });

        { // обновление fps счётчика
            var fps_str_buf = [1]u8{'$'} ** 6;
            _ = try std.fmt.bufPrint(&fps_str_buf, "{}", .{window.fps});
            _ = try std.unicode.utf8ToUtf16Le(&fps_str, &fps_str_buf);
        }

        window.clear(.{
            .color = .{ 0.1, 0.1, 0.1, 1.0 },
        });
        try drawer.draw();
        window.swap();
    }
}
