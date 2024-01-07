const std = @import("std");
const log = std.log.scoped(.main);
const c = @import("c.zig");
const W = std.unicode.utf8ToUtf16LeStringLiteral;

const window = @import("window.zig");
const input = @import("input.zig");
const gui = @import("gui.zig");
const camera = @import("camera.zig");
const world = @import("world.zig");
const drawer = @import("drawer.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    try window.init(.{ .title = "krateroid" });
    defer window.deinit();

    try gui.init(.{ .allocator = allocator, .scale = 3 });
    defer gui.deinit();

    _ = try gui.button(.{
        .text = W("<play>"),
        .rect = .{ .min = .{ -32, -26 }, .max = .{ 32, -10 } },
        .alignment = .{ .v = .center, .h = .center },
    });

    _ = try gui.button(.{
        .text = W("<settings>"),
        .rect = .{ .min = .{ -32, -8 }, .max = .{ 32, 8 } },
        .alignment = .{ .v = .center, .h = .center },
    });

    const button_exit = try gui.button(.{
        .text = W("<exit>"),
        .rect = .{ .min = .{ -32, 10 }, .max = .{ 32, 26 } },
        .alignment = .{ .v = .center, .h = .center },
    });

    _ = try gui.text(.{
        .data = W("krateroid prototype 1"),
        .pos = .{ 2, 1 },
    });

    _ = try gui.text(.{
        .data = W("fps:"),
        .pos = .{ 2, 9 },
    });

    var fps_str = [1]u16{'0'} ** 6;
    _ = try gui.text(.{
        .data = &fps_str,
        .pos = .{ 16, 9 },
        .usage = .dynamic,
    });

    _ = try gui.text(.{
        .data = W("gitlab.com/kussakaa/krateroid"),
        .pos = .{ 2, -8 },
        .alignment = .{ .v = .bottom },
    });

    try world.init(.{ .allocator = allocator });
    defer world.deinit();

    _ = try world.chunk(.{
        .pos = .{ 0, 0 },
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
                        if (id == c.SDL_SCANCODE_ESCAPE) break :loop;
                        if (id == c.SDL_SCANCODE_O) gui.scale = @max(gui.scale - 1, 1);
                        if (id == c.SDL_SCANCODE_P) gui.scale = @min(gui.scale + 1, 8);
                        if (id == c.SDL_SCANCODE_H) c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);
                    },
                    .unpress => |_| {},
                },
                .mouse => |m| switch (m) {
                    .button => |b| switch (b) {
                        .press => |id| {
                            if (id == 1) gui.cursor.press();
                        },
                        .unpress => |id| {
                            if (id == 1) gui.cursor.unpress();
                        },
                    },
                    .pos => |pos| gui.cursor.setPos(pos),
                },
                else => {},
            }
        }

        guiproc: while (true) {
            switch (gui.pollEvent()) {
                .none => break :guiproc,
                .button => |b| switch (b) {
                    .press => |_| {},
                    .unpress => |id| {
                        if (id == button_exit) break :loop;
                    },
                },
            }
        }

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
