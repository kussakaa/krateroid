const std = @import("std");
const gfx = @import("../gfx.zig");

const Allocator = std.mem.Allocator;
var _allocator: std.mem.Allocator = undefined;

pub const world = struct {
    pub const chunk = struct {
        const world_terra_v = @import("../world.zig").getTerraV();
        pub var vertex_buffers: [world_terra_v]?gfx.Buffer = undefined;
        pub var normal_buffers: [world_terra_v]?gfx.Buffer = undefined;
        pub var meshes: [world_terra_v]?gfx.Mesh = undefined;
        pub var program: gfx.Program = undefined;
        pub const uniform = struct {
            pub var model: gfx.Uniform = undefined;
            pub var view: gfx.Uniform = undefined;
            pub var proj: gfx.Uniform = undefined;
            pub const light = struct {
                pub var color: gfx.Uniform = undefined;
                pub var direction: gfx.Uniform = undefined;
                pub var ambient: gfx.Uniform = undefined;
                pub var diffuse: gfx.Uniform = undefined;
                pub var specular: gfx.Uniform = undefined;
            };
            pub const chunk = struct {
                pub var width: gfx.Uniform = undefined;
                pub var pos: gfx.Uniform = undefined;
            };
        };
        pub const texture = struct {
            pub var dirt: gfx.Texture = undefined;
            pub var grass: gfx.Texture = undefined;
            pub var sand: gfx.Texture = undefined;
            pub var stone: gfx.Texture = undefined;
        };
    };

    pub const actor = struct {
        pub var vertex_buffer: gfx.Buffer = undefined;
        pub var normal_buffer: gfx.Buffer = undefined;
        pub var mesh: gfx.Mesh = undefined;
        pub var program: gfx.Program = undefined;
        pub const uniform = struct {};
    };

    pub const projectile = struct {
        pub var vertex_buffer: gfx.Buffer = undefined;
        pub var mesh: gfx.Mesh = undefined;
        pub var program: gfx.Program = undefined;
        pub const uniform = struct {
            pub var model: gfx.Uniform = undefined;
            pub var view: gfx.Uniform = undefined;
            pub var proj: gfx.Uniform = undefined;
        };
    };
};

pub const shape = struct {
    pub const line = struct {
        pub var vertex_buffer: gfx.Buffer = undefined;
        pub var color_buffer: gfx.Buffer = undefined;
        pub var mesh: gfx.Mesh = undefined;
        pub var program: gfx.Program = undefined;
        pub const uniform = struct {
            pub var model: gfx.Uniform = undefined;
            pub var view: gfx.Uniform = undefined;
            pub var proj: gfx.Uniform = undefined;
        };
    };
};

pub const gui = struct {
    pub const rect = struct {
        pub var buffer: gfx.Buffer = undefined;
        pub var mesh: gfx.Mesh = undefined;
        pub var program: gfx.Program = undefined;
        pub const uniform = struct {
            pub var vpsize: gfx.Uniform = undefined;
            pub var scale: gfx.Uniform = undefined;
            pub var rect: gfx.Uniform = undefined;
            pub var texrect: gfx.Uniform = undefined;
        };
    };

    pub const panel = struct {
        pub var texture: gfx.Texture = undefined;
    };

    pub const button = struct {
        pub var texture: gfx.Texture = undefined;
    };

    pub const switcher = struct {
        pub var texture: gfx.Texture = undefined;
    };

    pub const slider = struct {
        pub var texture: gfx.Texture = undefined;
    };

    pub const text = struct {
        pub var program: gfx.Program = undefined;

        pub const uniform = struct {
            pub var vpsize: gfx.Uniform = undefined;
            pub var scale: gfx.Uniform = undefined;
            pub var pos: gfx.Uniform = undefined;
            pub var tex: gfx.Uniform = undefined;
            pub var color: gfx.Uniform = undefined;
        };

        pub var texture: gfx.Texture = undefined;
    };

    pub const cursor = struct {
        pub var texture: gfx.Texture = undefined;
    };
};

pub fn init(allocator: Allocator) !void {
    _allocator = allocator;
    try initWorld();
    try initShape();
    try initGui();
}

pub fn deinit() void {
    { // GUI
        gui.cursor.texture.deinit();
        gui.text.texture.deinit();
        gui.text.program.deinit();
        gui.slider.texture.deinit();
        gui.switcher.texture.deinit();
        gui.button.texture.deinit();
        gui.panel.texture.deinit();
        gui.rect.program.deinit();
        gui.rect.mesh.deinit();
        gui.rect.buffer.deinit();
    }

    { // SHAPE
        shape.line.program.deinit();
        shape.line.mesh.deinit();
        shape.line.vertex_buffer.deinit();
        shape.line.color_buffer.deinit();
    }

    { // WORLD

        world.projectile.program.deinit();
        world.projectile.mesh.deinit();
        world.projectile.vertex_buffer.deinit();

        world.chunk.texture.dirt.deinit();
        world.chunk.texture.grass.deinit();
        world.chunk.texture.sand.deinit();
        world.chunk.texture.stone.deinit();
        world.chunk.program.deinit();
        for (world.chunk.meshes) |item| if (item != null) item.?.deinit();
        for (world.chunk.vertex_buffers) |item| if (item != null) item.?.deinit();
        for (world.chunk.normal_buffers) |item| if (item != null) item.?.deinit();
    }
}

fn initWorld() !void {
    try initWorldChunk();
    try initWorldProjectile();
}

fn initWorldChunk() !void {
    @memset(world.chunk.normal_buffers[0..], null);
    @memset(world.chunk.vertex_buffers[0..], null);
    @memset(world.chunk.meshes[0..], null);

    world.chunk.program = try gfx.Program.init(_allocator, "world/chunk");

    world.chunk.uniform.model = try gfx.Uniform.init(world.chunk.program, "model");
    world.chunk.uniform.view = try gfx.Uniform.init(world.chunk.program, "view");
    world.chunk.uniform.proj = try gfx.Uniform.init(world.chunk.program, "proj");

    world.chunk.uniform.light.color = try gfx.Uniform.init(world.chunk.program, "light.color");
    world.chunk.uniform.light.direction = try gfx.Uniform.init(world.chunk.program, "light.direction");
    world.chunk.uniform.light.ambient = try gfx.Uniform.init(world.chunk.program, "light.ambient");
    world.chunk.uniform.light.diffuse = try gfx.Uniform.init(world.chunk.program, "light.diffuse");
    world.chunk.uniform.light.specular = try gfx.Uniform.init(world.chunk.program, "light.specular");

    world.chunk.uniform.chunk.width = try gfx.Uniform.init(world.chunk.program, "chunk.width");
    world.chunk.uniform.chunk.pos = try gfx.Uniform.init(world.chunk.program, "chunk.pos");

    world.chunk.texture.dirt = try gfx.Texture.init(_allocator, "world/dirt.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
    world.chunk.texture.grass = try gfx.Texture.init(_allocator, "world/grass.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
    world.chunk.texture.sand = try gfx.Texture.init(_allocator, "world/sand.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
    world.chunk.texture.stone = try gfx.Texture.init(_allocator, "world/stone.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
}

fn initWorldProjectile() !void {
    const bytes = @import("../world.zig").getProjectilesPosBytes();
    const cnt = @import("../world.zig").getProjectilesMaxCnt();

    world.projectile.vertex_buffer = try gfx.Buffer.init(.{
        .name = "world projectile vertex",
        .target = .vbo,
        .datatype = .f32,
        .vertsize = 4,
        .usage = .dynamic_draw,
    });
    world.projectile.vertex_buffer.data(bytes);

    world.projectile.mesh = try gfx.Mesh.init(.{
        .name = "world projectile mesh",
        .buffers = &.{world.projectile.vertex_buffer},
        .vertcnt = cnt,
        .drawmode = .points,
    });

    world.projectile.program = try gfx.Program.init(_allocator, "world/projectile");
    world.projectile.uniform.model = try gfx.Uniform.init(world.projectile.program, "model");
    world.projectile.uniform.view = try gfx.Uniform.init(world.projectile.program, "view");
    world.projectile.uniform.proj = try gfx.Uniform.init(world.projectile.program, "proj");
}

fn initShape() !void {
    try initShapeLine();
}

fn initShapeLine() !void {
    const vertex_bytes = @import("../shape.zig").getLinesVertexBytes();
    const color_bytes = @import("../shape.zig").getLinesColorBytes();
    const cnt = @import("../shape.zig").getLinesMaxCnt() * 2;

    shape.line.vertex_buffer = try gfx.Buffer.init(.{
        .name = "shape line vertex",
        .target = .vbo,
        .datatype = .f32,
        .vertsize = 4,
        .usage = .dynamic_draw,
    });
    shape.line.vertex_buffer.data(vertex_bytes);

    shape.line.color_buffer = try gfx.Buffer.init(.{
        .name = "shape line color",
        .target = .vbo,
        .datatype = .f32,
        .vertsize = 4,
        .usage = .dynamic_draw,
    });
    shape.line.color_buffer.data(color_bytes);

    shape.line.mesh = try gfx.Mesh.init(.{
        .name = "shape line mesh",
        .buffers = &.{ shape.line.vertex_buffer, shape.line.color_buffer },
        .vertcnt = cnt,
        .drawmode = .lines,
    });

    shape.line.program = try gfx.Program.init(_allocator, "shape/line");
    shape.line.uniform.model = try gfx.Uniform.init(shape.line.program, "model");
    shape.line.uniform.view = try gfx.Uniform.init(shape.line.program, "view");
    shape.line.uniform.proj = try gfx.Uniform.init(shape.line.program, "proj");
}

fn initGui() !void {
    try initGuiRect();
    try initGuiPanel();
    try initGuiButton();
    try initGuiSwitcher();
    try initGuiSlider();
    try initGuiText();
    try initGuiCursor();
}

fn initGuiRect() !void {
    gui.rect.buffer = try gfx.Buffer.init(.{
        .name = "gui rect vertex",
        .target = .vbo,
        .datatype = .u8,
        .vertsize = 2,
        .usage = .static_draw,
    });
    gui.rect.buffer.data(&.{ 0, 0, 0, 1, 1, 0, 1, 1 });
    gui.rect.mesh = try gfx.Mesh.init(.{
        .name = "gui rect mesh",
        .buffers = &.{gui.rect.buffer},
        .vertcnt = 4,
        .drawmode = .triangle_strip,
    });

    gui.rect.program = try gfx.Program.init(_allocator, "gui/rect");
    gui.rect.uniform.vpsize = try gfx.Uniform.init(gui.rect.program, "vpsize");
    gui.rect.uniform.scale = try gfx.Uniform.init(gui.rect.program, "scale");
    gui.rect.uniform.rect = try gfx.Uniform.init(gui.rect.program, "rect");
    gui.rect.uniform.texrect = try gfx.Uniform.init(gui.rect.program, "texrect");
}

fn initGuiPanel() !void {
    gui.panel.texture = try gfx.Texture.init(_allocator, "gui/panel.png", .{});
}

fn initGuiButton() !void {
    gui.button.texture = try gfx.Texture.init(_allocator, "gui/button.png", .{});
}

fn initGuiSwitcher() !void {
    gui.switcher.texture = try gfx.Texture.init(_allocator, "gui/switcher.png", .{});
}

fn initGuiSlider() !void {
    gui.slider.texture = try gfx.Texture.init(_allocator, "gui/slider.png", .{});
}

fn initGuiText() !void {
    gui.text.program = try gfx.Program.init(_allocator, "gui/text");
    gui.text.uniform.vpsize = try gfx.Uniform.init(gui.text.program, "vpsize");
    gui.text.uniform.scale = try gfx.Uniform.init(gui.text.program, "scale");
    gui.text.uniform.pos = try gfx.Uniform.init(gui.text.program, "pos");
    gui.text.uniform.tex = try gfx.Uniform.init(gui.text.program, "tex");
    gui.text.uniform.color = try gfx.Uniform.init(gui.text.program, "color");
    gui.text.texture = try gfx.Texture.init(_allocator, "gui/text.png", .{});
}

fn initGuiCursor() !void {
    gui.cursor.texture = try gfx.Texture.init(_allocator, "gui/cursor.png", .{});
}
