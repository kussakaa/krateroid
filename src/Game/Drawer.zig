const std = @import("std");
const Allocator = std.mem.Allocator;

const linmath = @import("../linmath.zig");

const Window = @import("Window.zig");
const Gui = @import("Gui.zig");

const Verts = @import("Drawer/Verts.zig");
const Elems = @import("Drawer/Elems.zig");
const Texture = @import("Drawer/Texture.zig");
const Shader = @import("Drawer/Shader.zig");
const Program = @import("Drawer/Program.zig");

const Drawer = @This();
gui: struct {
    scale: i32,
    rect: struct {
        verts: Verts,
        elems: Elems,
    },
    text: struct {
        program: Program,
        texture: Texture,
        verts: std.ArrayList(Verts),
    },
    button: struct {
        program: Program,
        texture: [Gui.Button.State.count]Texture,
    },
},
world: struct {},

pub const InitInfo = struct {
    allocator: Allocator,
    scale: i32 = 3,
};

pub fn init(info: InitInfo) !Drawer {
    const allocator = info.allocator;
    return Drawer{
        .gui = .{
            .scale = info.scale,
            .rect = .{
                .verts = try Verts.init(.{
                    .data = &.{ 0.0, 0.0, 0.0, -1.0, 1.0, -1.0, 1.0, 0.0 },
                    .attrs = &.{2},
                }),
                .elems = try Elems.init(.{
                    .data = &.{ 0, 1, 2, 2, 3, 0 },
                }),
            },
            .text = .{
                .program = try Program.init(
                    allocator,
                    &.{
                        try Shader.initFormFile(allocator, "core/gui/text/vertex.glsl", .vertex),
                        try Shader.initFormFile(allocator, "core/gui/text/fragment.glsl", .fragment),
                    },
                    &.{ "model", "color" },
                ),
                .texture = try Texture.init("core/gui/text/font.png"),
                .verts = std.ArrayList(Verts).init(allocator),
            },
            .button = .{
                .program = try Program.init(
                    allocator,
                    &.{
                        try Shader.initFormFile(allocator, "core/gui/button/vertex.glsl", .vertex),
                        try Shader.initFormFile(allocator, "core/gui/button/fragment.glsl", .fragment),
                    },
                    &.{ "model", "vpsize", "scale", "rect", "texsize" },
                ),
                .texture = .{
                    try Texture.init("core/gui/button/empty.png"),
                    try Texture.init("core/gui/button/focus.png"),
                    try Texture.init("core/gui/button/press.png"),
                },
            },
        },
        .world = .{},
    };
}

pub fn deinit(self: Drawer) void {
    self.gui.rect.verts.deinit();
    self.gui.rect.elems.deinit();
    self.gui.text.program.deinit();
    self.gui.text.texture.deinit();
    self.gui.button.program.deinit();
    self.gui.button.texture[0].deinit();
    self.gui.button.texture[1].deinit();
    self.gui.button.texture[2].deinit();
}

pub fn draw(drawer: Drawer, window: Window, obj: anytype) !void {
    switch (comptime @TypeOf(obj)) {
        Gui => {
            for (obj.controls.items) |control| {
                switch (control) {
                    .button => try drawer.draw(window, control.button),
                    .text => {},
                }
            }
        },
        Gui.Text => {},
        Gui.Button => {
            const button = obj;
            const pos = button.alignment.transform(button.rect.scale(drawer.gui.scale), window.size).min;
            const size = button.rect.scale(drawer.gui.scale).size();

            var model: linmath.Mat = linmath.identity(linmath.Mat);
            model[0][3] = @as(f32, @floatFromInt(pos[0])) / @as(f32, @floatFromInt(window.size[0])) * 2.0 - 1.0;
            model[1][3] = @as(f32, @floatFromInt(pos[1])) / @as(f32, @floatFromInt(window.size[1])) * -2.0 + 1.0;
            model[0][0] = @as(f32, @floatFromInt(size[0])) / @as(f32, @floatFromInt(window.size[0])) * 2.0;
            model[1][1] = @as(f32, @floatFromInt(size[1])) / @as(f32, @floatFromInt(window.size[1])) * 2.0;

            drawer.gui.button.program.use();
            drawer.gui.button.program.setUniform(0, model);
            drawer.gui.button.program.setUniform(1, window.size);
            drawer.gui.button.program.setUniform(2, drawer.gui.scale);
            drawer.gui.button.program.setUniform(3, button.alignment.transform(button.rect.scale(drawer.gui.scale), window.size).vector());
            drawer.gui.button.program.setUniform(4, drawer.gui.button.texture[@intFromEnum(button.state)].size);
            drawer.gui.button.texture[@intFromEnum(button.state)].use();
            try drawer.gui.rect.elems.draw(drawer.gui.rect.verts);
        },
        else => @compileError("invalid object type for Game.Drawer.draw()"),
    }
}

//pub fn drawText(state: State, text: Text) !void {
//    const pos = text.alignment.transform(text.pos * Point{ state.scale, state.scale }, state.vpsize);
//    const matrix = trasformMatrix(pos, .{ state.scale, state.scale }, state.vpsize);
//    state.render.text.program.use();
//    state.render.text.program.setUniform(0, matrix);
//    state.render.text.program.setUniform(1, text.style.color);
//    state.render.text.texture.use();
//    try text.vertices.draw();
//}
//
//pub fn drawButton(state: State, button: Button) !void {
//    const pos = button.alignment.transform(button.rect.scale(state.scale), state.vpsize).min;
//    const size = button.rect.scale(state.scale).size();
//    const matrix: Mat = trasformMatrix(pos, size, state.vpsize);
//    state.render.button.program.use();
//    state.render.button.program.setUniform(0, matrix);
//    state.render.button.program.setUniform(1, state.vpsize);
//    state.render.button.program.setUniform(2, state.scale);
//    state.render.button.program.setUniform(3, button.alignment.transform(button.rect.scale(state.scale), state.vpsize).vector());
//    state.render.button.program.setUniform(4, button.style.states[@intFromEnum(button.state)].texture.size);
//    button.style.states[@intFromEnum(button.state)].texture.use();
//    try state.render.rect.mesh.draw();
//
//    var text: Text = button.text;
//    text.pos = button.rect.min + @divTrunc(button.rect.size() - button.text.size, Point{ 2, 2 });
//    text.style = button.style.states[@intFromEnum(button.state)].text;
//    try drawText(state, text);
//}
