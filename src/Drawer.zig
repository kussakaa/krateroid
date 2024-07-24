allocator: Allocator,
gfx: Gfx,

world: struct {
    ctx: *const World,
    camera: Gfx.Camera,
    program: Gfx.Program,

    light: struct {
        color: zm.Vec,
        dir: zm.Vec,
        ambient: f32,
        diffuse: f32,
        specular: f32,
    },
},

gui: struct {
    ctx: *const Gui,
},

pub const Config = struct {
    gfx: Gfx,
    world: struct {
        ctx: *const World,
        camera: Gfx.Camera.Config,
    },

    gui: struct {
        ctx: *const Gui,
    },
};

pub fn init(allocator: Allocator, config: Config) !Self {
    const gfx = config.gfx;
    const self = Self{
        .allocator = allocator,
        .gfx = gfx,
        .world = .{
            .ctx = config.world.ctx,
            .camera = Gfx.Camera.init(config.world.camera),
            .program = try Gfx.Program.init(allocator, .{
                .name = "world",
                .uniforms = &.{
                    "light.color",
                    "lignt.dir",
                    "light.ambient",
                    "light.diffuse",
                    "light.specular",
                },
            }),
            .light = .{
                .color = .{ 1.0, 1.0, 1.0, 1.0 },
                .dir = .{ 0.0, 0.0, 1.0, 1.0 },
                .ambient = 0.3,
                .diffuse = 0.2,
                .specular = 3,
            },
        },
        .gui = .{
            .ctx = config.gui.ctx,
        },
    };

    log.succes(.init, "DRAWER System", .{});

    return self;
}

pub fn deinit(self: Self) void {
    self.world.program.deinit();
}

pub fn draw(self: *Self) bool {
    self.gfx.clear();

    // WORLD
    {
        const world = self.world;
        world.program.use();
        world.program.uniforms[0].set(world.light.color); // light.color
        world.program.uniforms[1].set(world.light.dir); // light.dir
        world.program.uniforms[2].set(world.light.ambient); // light.ambient
        world.program.uniforms[3].set(world.light.diffuse); // light.diffuse
        world.program.uniforms[4].set(world.light.specular); // light.specular
    }

    // GUi
    //if (self.gui) |_| {}

    // IMGUI
    const fb_size = self.gfx.window.handle.getFramebufferSize();
    imgui.backend.newFrame(@intCast(fb_size[0]), @intCast(fb_size[1]));

    if (imgui.begin("debug", .{})) {
        if (imgui.treeNode("camera")) {
            _ = imgui.sliderFloat4("pos", .{ .v = &self.world.camera.pos, .min = 0.0, .max = 32.0 });
            _ = imgui.sliderFloat4("rot", .{ .v = &self.world.camera.rot, .min = 0.0, .max = std.math.pi * 2 });
            _ = imgui.sliderFloat("scale", .{ .v = &self.world.camera.scale, .min = 0.1, .max = 32.0 });
            _ = imgui.sliderFloat("ratio", .{ .v = &self.world.camera.ratio, .min = 0.5, .max = 2.0 });
            imgui.treePop();
        }

        if (imgui.treeNode("light")) {
            _ = imgui.sliderFloat4("color", .{ .v = &self.world.light.color, .min = 0.0, .max = 1.0 });
            _ = imgui.sliderFloat4("direction", .{ .v = &self.world.light.dir, .min = -1.0, .max = 1.0 });
            _ = imgui.sliderFloat("ambient", .{ .v = &self.world.light.ambient, .min = 0.0, .max = 1.0 });
            _ = imgui.sliderFloat("diffuse", .{ .v = &self.world.light.diffuse, .min = 0.0, .max = 1.0 });
            _ = imgui.sliderFloat("specular", .{ .v = &self.world.light.specular, .min = 0.0, .max = 10.0 });
            imgui.treePop();
        }
        imgui.end();
    }

    imgui.backend.draw();
    self.gfx.swapBuffers();
    return true;
}

const Self = @This();
const Gfx = @import("Gfx.zig");
const Allocator = std.mem.Allocator;

const World = @import("World.zig");
const Gui = @import("Gui.zig");

const zm = @import("zmath");
const gl = @import("zopengl").bindings;
const imgui = @import("zgui");
const std = @import("std");
const log = @import("log");
