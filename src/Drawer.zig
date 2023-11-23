const std = @import("std");
const Allocator = std.mem.Allocator;
const Gui = @import("Gui.zig");

const Drawer = @This();

pub const Mesh = @import("Drawer/Mesh.zig");
pub const Texture = @import("Drawer/Texture.zig");
pub const Shader = @import("Drawer/Shader.zig");
pub const Program = @import("Drawer/Program.zig");

gui: struct {
    scale: i32,
    rect: struct {
        mesh: Mesh,
    },
    text: struct {
        program: Program,
        texture: Texture,
    },
    button: struct {
        program: Program,
        texture: struct {
            empty: Texture,
            focus: Texture,
            press: Texture,
        },
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
                .mesh = .{
                    .verts = try Mesh.Verts.init(.{
                        .data = &.{ 0.0, 0.0, 0.0, -1.0, 1.0, -1.0, 1.0, 0.0 },
                        .attrs = &.{2},
                    }),
                    .elems = try Mesh.Elems.init(.{
                        .data = &.{ 0, 1, 2, 2, 3, 0 },
                    }),
                },
            },
            .text = .{
                .program = try Program.init(
                    allocator,
                    &.{
                        try Shader.initFormFile(
                            allocator,
                            "core/gui/text/vertex.glsl",
                            Shader.Type.vertex,
                        ),
                        try Shader.initFormFile(
                            allocator,
                            "core/gui/text/fragment.glsl",
                            Shader.Type.fragment,
                        ),
                    },
                    &.{ "matrix", "color" },
                ),
                .texture = try Texture.init("core/gui/text/font.png"),
            },
            .button = .{
                .program = try Program.init(
                    allocator,
                    &.{
                        try Shader.initFormFile(
                            allocator,
                            "core/gui/button/vertex.glsl",
                            Shader.Type.vertex,
                        ),
                        try Shader.initFormFile(
                            allocator,
                            "core/gui/button/fragment.glsl",
                            Shader.Type.fragment,
                        ),
                    },
                    &.{ "matrix", "vpsize", "scale", "rect", "texsize" },
                ),
                .texture = .{
                    .empty = try Texture.init("core/gui/button/empty.png"),
                    .focus = try Texture.init("core/gui/button/focus.png"),
                    .press = try Texture.init("core/gui/button/press.png"),
                },
            },
        },
        .world = .{},
    };
}

pub fn deinit(self: Drawer) void {
    self.gui.rect.mesh.verts.deinit();
    self.gui.rect.mesh.elems.deinit();
    self.gui.text.program.deinit();
    self.gui.text.texture.deinit();
    self.gui.button.program.deinit();
    self.gui.button.texture.empty.deinit();
    self.gui.button.texture.focus.deinit();
    self.gui.button.texture.press.deinit();
}
