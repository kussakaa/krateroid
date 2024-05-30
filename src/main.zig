const std = @import("std");
const zm = @import("zmath");
const gl = @import("zopengl").bindings;
const stb = @import("zstbi");
const audio = @import("zaudio");

const log = std.log.scoped(.main);
const pi = std.math.pi;

const Vec = zm.Vec;
const Mat = zm.Mat;

const config = @import("config.zig");
const window = @import("window.zig");
const input = @import("input.zig");
const gfx = @import("gfx.zig");
const camera = @import("camera.zig");
const terra = @import("terra.zig");
const shape = @import("shape.zig");
const gui = @import("gui.zig");
const menus = @import("menus.zig");
const drawer = @import("drawer.zig");

pub fn main() !void {
    std.debug.print("\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator: std.mem.Allocator = gpa.allocator();
    defer _ = gpa.deinit();

    audio.init(allocator);
    defer audio.deinit();

    const audio_engine = try audio.Engine.create(null);
    defer audio_engine.destroy();

    try audio_engine.setVolume(config.audio.volume);

    try window.init(.{ .title = "krateroid" });
    defer window.deinit();

    const cursor = struct {
        var pos: @Vector(2, i32) = .{ 0, 0 };
        var delta: @Vector(2, i32) = .{ 0, 0 };
    };

    var is_camera_move: bool = false;
    var is_camera_rotate: bool = false;
    camera.pos = .{ 64.0, 64.0, 0.0, 1.0 };
    camera.rot = .{ -pi / 6.0, 0.0, 0.0, 1.0 };
    camera.scale = 50.0;

    try terra.init(allocator, 696969);
    defer terra.deinit();

    shape.init();
    defer shape.deinit();

    try gui.init(.{ .allocator = allocator, .scale = 3 });
    defer gui.deinit();

    try menus.init();

    gfx.init(.{ .allocator = allocator });
    defer gfx.deinit();

    try drawer.init(allocator);
    defer drawer.deinit();

    loop: while (true) {
        inputproc: while (true) {
            switch (input.events.pull()) {
                .none => break :inputproc,
                .quit => break :loop,

                .key => |k| switch (k) {
                    .pressed => |id| {
                        if (id == .escape) {
                            gui.menus.items[menus.main.id].show = !gui.menus.items[menus.main.id].show;
                            gui.menus.items[menus.settings.id].show = false;
                        }
                        if (id == .space) {}
                        if (id == .f3) {
                            config.debug.show_info = !config.debug.show_info;
                        }
                        if (id == .f5) {
                            config.debug.show_grid = !config.debug.show_grid;
                        }
                        if (id == .f10) break :loop;
                        if (id == .kp_minus) gui.scale = @max(gui.scale - 1, 1);
                        if (id == .kp_plus) gui.scale = @min(gui.scale + 1, 8);
                    },
                    .unpressed => |_| {},
                },

                .mouse => |m| switch (m) {
                    .pressed => |id| {
                        if (id == 1) {
                            is_camera_move = true;
                            gui.cursor.press = true;
                            gui.update();
                        }
                        if (id == 3) {
                            is_camera_rotate = true;
                        }
                    },
                    .unpressed => |id| {
                        if (id == 1) {
                            is_camera_move = false;
                            gui.cursor.press = false;
                            gui.update();
                        }
                        if (id == 3) {
                            is_camera_rotate = false;
                        }
                    },
                    .moved => |pos| {
                        cursor.delta = pos - cursor.pos;
                        cursor.pos = pos;

                        if (is_camera_move and !gui.menus.items[menus.main.id].show and !gui.menus.items[menus.settings.id].show) {
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

                        if (is_camera_rotate and !gui.menus.items[menus.main.id].show and !gui.menus.items[menus.settings.id].show) {
                            const speed = 0.003; // radians
                            const dtx = @as(f32, @floatFromInt(cursor.delta[0]));
                            const dty = @as(f32, @floatFromInt(cursor.delta[1]));
                            camera.rot += Vec{
                                dty * speed,
                                0.0,
                                dtx * speed,
                                0.0,
                            };
                        }

                        gui.cursor.pos = pos;
                        gui.update();
                    },

                    .scrolled => |scroll| {
                        if (!gui.menus.items[menus.main.id].show and !gui.menus.items[menus.settings.id].show) {
                            camera.scale = camera.scale * (1.0 - @as(f32, @floatFromInt(scroll)) * 0.1);
                        }
                    },
                },

                .window => |w| switch (w) {
                    .resized => |s| {
                        window.resize(s);
                    },
                },
            }
        }

        guiproc: while (true) {
            switch (gui.events.pull()) {
                .none => break :guiproc,

                .button => |item| switch (item) {
                    .focused => |_| {
                        try audio_engine.playSound("data/sound/focus.wav", null);
                    },
                    .unfocused => |_| {},
                    .pressed => |_| {},
                    .unpressed => |id| {
                        try audio_engine.playSound("data/sound/press.wav", null);
                        if (id == menus.main.button.play) {
                            gui.menus.items[menus.main.id].show = false;
                            gui.menus.items[menus.settings.id].show = false;
                        } else if (id == menus.main.button.settings) {
                            gui.menus.items[menus.settings.id].show = !gui.menus.items[menus.settings.id].show;
                        } else if (id == menus.main.button.exit) {
                            break :loop;
                        }
                    },
                },

                .switcher => |item| switch (item) {
                    .focused => |_| {
                        try audio_engine.playSound("data/sound/focus.wav", null);
                    },
                    .unfocused => |_| {},
                    .pressed => |_| {},
                    .unpressed => |_| {},
                    .switched => |switched| {
                        try audio_engine.playSound("data/sound/press.wav", null);
                        if (switched.id == menus.settings.switcher.show_info) {
                            config.debug.show_info = switched.data;
                            gui.menus.items[menus.info.id].show = config.debug.show_info;
                        } else if (switched.id == menus.settings.switcher.show_grid) {
                            config.debug.show_grid = switched.data;
                        }
                    },
                },

                .slider => |item| switch (item) {
                    .focused => |_| {
                        try audio_engine.playSound("data/sound/focus.wav", null);
                    },
                    .unfocused => |_| {},
                    .pressed => |_| {},
                    .unpressed => |_| {
                        try audio_engine.playSound("data/sound/press.wav", null);
                    },
                    .scrolled => |s| {
                        if (s.id == menus.settings.slider.volume) {
                            config.audio.volume = s.data;
                            try audio_engine.setVolume(config.audio.volume);
                        }
                    },
                },
            }
        }

        shape.update();
        try menus.update();
        camera.update();

        try drawer.draw();

        window.swap();
    }
}
