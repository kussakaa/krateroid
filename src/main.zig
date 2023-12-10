const std = @import("std");
const log = std.log.scoped(.main);
const c = @import("c.zig");
const W = std.unicode.utf8ToUtf16LeStringLiteral;

const window = @import("window.zig");
const input = @import("input.zig");
const drawer = @import("drawer.zig");
const gui = @import("gui.zig");
//const world = @import("world.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    try window.init(.{ .title = "krateroid" });
    try gui.init(.{ .allocator = allocator });
    try drawer.init(.{ .allocator = allocator });

    defer window.deinit();
    defer drawer.deinit();
    defer gui.deinit();

    try gui.button(.{
        .text = W("играть"),
        .rect = .{ .min = .{ -32, -26 }, .max = .{ 32, -10 } },
        .alignment = .{ .v = .center, .h = .center },
    });

    try gui.button(.{
        .text = W("настройки"),
        .rect = .{ .min = .{ -32, -8 }, .max = .{ 32, 8 } },
        .alignment = .{ .v = .center, .h = .center },
    });

    try gui.button(.{
        .text = W("выход"),
        .rect = .{ .min = .{ -32, 10 }, .max = .{ 32, 26 } },
        .alignment = .{ .v = .center, .h = .center },
    });

    try gui.text(.{
        .data = W("krateroid prototype gui"),
        .pos = .{ 2, 1 },
    });

    loop: while (true) {
        inputproc: while (true) {
            switch (input.pollEvent()) {
                .none => break :inputproc,
                .quit => break :loop,
                .key => |k| switch (k) {
                    .press => |id| {
                        if (id == c.SDL_SCANCODE_ESCAPE) break :loop;
                    },
                    .unpress => |_| {},
                },
                .mouse => |m| switch (m) {
                    .button => |b| switch (b) {
                        .press => |id| {
                            if (id == 1) gui.cursor_press();
                        },
                        .unpress => |id| {
                            if (id == 1) gui.cursor_unpress();
                        },
                    },
                    .pos => |pos| gui.cursor_pos(pos),
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
                        if (id == 2) break :loop;
                    },
                },
            }
        }

        window.clear(.{
            .color = .{ 0.1, 0.1, 0.1, 1.0 },
        });
        try drawer.draw();
        window.swap();
    }
}
