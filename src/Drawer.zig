allocator: Allocator,
gfx: Gfx,

world: struct {
    ctx: *const World,
    camera: Gfx.Camera,
    program: Gfx.Program,
    texture: struct {
        dirt: Gfx.Texture,
        sand: Gfx.Texture,
        stone: Gfx.Texture,
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
        program: []const u8 = "world",
        texture: struct {
            dirt: []const u8 = "world/dirt.png",
            sand: []const u8 = "world/sand.png",
            stone: []const u8 = "world/stone.png",
        } = .{},
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
            .program = try Gfx.Program.init(allocator, .{ .name = config.world.program }),
            .texture = .{
                .dirt = try Gfx.Texture.init(allocator, .{ .name = config.world.texture.dirt }),
                .sand = try Gfx.Texture.init(allocator, .{ .name = config.world.texture.sand }),
                .stone = try Gfx.Texture.init(allocator, .{ .name = config.world.texture.stone }),
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
    self.world.texture.dirt.deinit();
    self.world.texture.sand.deinit();
    self.world.texture.stone.deinit();
}

pub fn draw(self: *Self) bool {
    self.gfx.clear();

    // WORLD
    {
        const world = self.world;
        world.program.use();
    }

    // GUi
    //if (self.gui) |_| {}

    // IMGUI
    const fb_size = self.gfx.window.handle.getFramebufferSize();
    imgui.backend.newFrame(@intCast(fb_size[0]), @intCast(fb_size[1]));

    if (imgui.begin("Camera", .{})) {
        _ = imgui.sliderFloat4("pos", .{ .v = &self.world.camera.pos, .min = 0.0, .max = 32.0 });
        _ = imgui.sliderFloat4("rot", .{ .v = &self.world.camera.rot, .min = 0.0, .max = std.math.pi * 2 });
        _ = imgui.sliderFloat("scale", .{ .v = &self.world.camera.scale, .min = 0.1, .max = 32.0 });
        _ = imgui.sliderFloat("ratio", .{ .v = &self.world.camera.ratio, .min = 0.5, .max = 2.0 });
    }
    imgui.end();
    imgui.backend.draw();

    self.gfx.swapBuffers();
    return true;
}

const Self = @This();
const Gfx = @import("Gfx.zig");
const Allocator = std.mem.Allocator;

const World = @import("World.zig");
const Gui = @import("Gui.zig");

const gl = @import("zopengl").bindings;
const imgui = @import("zgui");
const std = @import("std");
const log = @import("log");
