const std = @import("std");
const c = @import("c.zig");
const U16 = std.unicode.utf8ToUtf16LeStringLiteral;

const Game = @import("Game.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var game = try Game.init(.{
        .allocator = allocator,
        .core = .{
            .window = .{
                .title = "krateroid",
                .size = .{ 800, 600 },
            },
        },
    });
    defer game.deinit();

    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_CULL_FACE);
    c.glEnable(c.GL_BLEND);
    c.glEnable(c.GL_MULTISAMPLE);
    c.glCullFace(c.GL_FRONT);
    c.glFrontFace(c.GL_CW);
    c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL);
    c.glLineWidth(1);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);

    //_ = try game.gui.button(.{
    //    .text = U16("играть"),
    //    .rect = .{ .min = .{ -32, -17 }, .max = .{ 32, -1 } },
    //    .alignment = .{ .horizontal = .center, .vertical = .center },
    //});

    //_ = try game.gui.button(.{
    //    .text = U16("выход"),
    //    .rect = .{ .min = .{ -32, 1 }, .max = .{ 32, 17 } },
    //    .alignment = .{ .horizontal = .center, .vertical = .center },
    //});

    //_ = try game.gui.text(.{
    //    .data = U16("krateroid prototype gui"),
    //    .pos = .{ 2, 1 },
    //});

    // счётчик кадров в секунду
    //_ = try game.gui.text(.{
    //    .data = U16("fps:$$$$$$"),
    //    .pos = .{ 2, 9 },
    //    .usage = .dynamic,
    //});

    var run = true;
    loop: while (run) {
        events: while (true) {
            const event = game.core.input.pollevents();
            switch (event) {
                .none => break :events,
                .quit => break :loop,
                else => {},
            }
        }

        //if (@divTrunc(c.SDL_GetTicks(), 1000) > seconds) {
        //    seconds = @divTrunc(c.SDL_GetTicks(), 1000);
        //    fps = frame;
        //    frame = 0;
        //    var buf: [10]u8 = [1]u8{'$'} ** 10;
        //    _ = try std.fmt.bufPrint(&buf, "fps:{}", .{fps});
        //    var buf16: [10]u16 = [1]u16{'$'} ** 10;
        //    const len16 = try std.unicode.utf8ToUtf16Le(buf16[0..], buf[0..]);
        //    try text_fps.subdata(gui_state, buf16[0..len16]);
        //}

        // Рисование
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glEnable(c.GL_DEPTH_TEST);
        c.glDisable(c.GL_DEPTH_TEST);

        try game.draw();

        //frame += 1;
    }
}
