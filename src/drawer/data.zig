const std = @import("std");

const Allocator = std.mem.Allocator;

const gfx = @import("../gfx.zig");
const world = @import("../world.zig");
const gui = @import("../gui.zig");

pub const terra = struct {
    pub var vertex_buffers: [world.terra.w * world.terra.w * world.terra.h]?gfx.Buffer = undefined;
    pub var normal_buffers: [world.terra.w * world.terra.w * world.terra.h]?gfx.Buffer = undefined;
    pub var meshes: [world.terra.w * world.terra.w * world.terra.h]?gfx.Mesh = undefined;

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

pub fn init(allocator: Allocator) !void {
    { // TERRA
        @memset(terra.normal_buffers[0..], null);
        @memset(terra.vertex_buffers[0..], null);
        @memset(terra.meshes[0..], null);

        terra.program = try gfx.Program.init(allocator, "terra");

        terra.uniform.model = try gfx.Uniform.init(terra.program, "model");
        terra.uniform.view = try gfx.Uniform.init(terra.program, "view");
        terra.uniform.proj = try gfx.Uniform.init(terra.program, "proj");

        terra.uniform.light.color = try gfx.Uniform.init(terra.program, "light.color");
        terra.uniform.light.direction = try gfx.Uniform.init(terra.program, "light.direction");
        terra.uniform.light.ambient = try gfx.Uniform.init(terra.program, "light.ambient");
        terra.uniform.light.diffuse = try gfx.Uniform.init(terra.program, "light.diffuse");
        terra.uniform.light.specular = try gfx.Uniform.init(terra.program, "light.specular");

        terra.uniform.chunk.width = try gfx.Uniform.init(terra.program, "chunk.width");
        terra.uniform.chunk.pos = try gfx.Uniform.init(terra.program, "chunk.pos");

        terra.texture.dirt = try gfx.Texture.init(allocator, "world/terra/dirt.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
        terra.texture.grass = try gfx.Texture.init(allocator, "world/terra/grass.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
        terra.texture.sand = try gfx.Texture.init(allocator, "world/terra/sand.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
        terra.texture.stone = try gfx.Texture.init(allocator, "world/terra/stone.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
    }

    { // LINE
        line.vertex_buffer = try gfx.Buffer.init(.{
            .name = "line color",
            .target = .vbo,
            .datatype = .f32,
            .vertsize = 3,
            .usage = .static_draw,
        });
        line.vertex_buffer.data(std.mem.sliceAsBytes(world.shape.lines.vertex[0..]));

        line.color_buffer = try gfx.Buffer.init(.{
            .name = "line vertex",
            .target = .vbo,
            .datatype = .f32,
            .vertsize = 4,
            .usage = .static_draw,
        });
        line.color_buffer.data(std.mem.sliceAsBytes(world.shape.lines.color[0..]));

        line.mesh = try gfx.Mesh.init(.{
            .name = "line",
            .buffers = &.{ line.vertex_buffer, line.color_buffer },
            .vertcnt = world.shape.lines.len,
            .drawmode = .lines,
        });

        line.program = try gfx.Program.init(allocator, "line");
        line.uniform.model = try gfx.Uniform.init(line.program, "model");
        line.uniform.view = try gfx.Uniform.init(line.program, "view");
        line.uniform.proj = try gfx.Uniform.init(line.program, "proj");
    }

    { // RECT
        rect.buffer = try gfx.Buffer.init(.{
            .name = "rect",
            .target = .vbo,
            .datatype = .u8,
            .vertsize = 2,
            .usage = .static_draw,
        });
        rect.buffer.data(&.{ 0, 0, 0, 1, 1, 0, 1, 1 });
        rect.mesh = try gfx.Mesh.init(.{
            .name = "rect",
            .buffers = &.{rect.buffer},
            .vertcnt = 4,
            .drawmode = .triangle_strip,
        });
        rect.program = try gfx.Program.init(allocator, "rect");
        rect.uniform.vpsize = try gfx.Uniform.init(rect.program, "vpsize");
        rect.uniform.scale = try gfx.Uniform.init(rect.program, "scale");
        rect.uniform.rect = try gfx.Uniform.init(rect.program, "rect");
        rect.uniform.texrect = try gfx.Uniform.init(rect.program, "texrect");
    }

    { // PANEL
        panel.texture = try gfx.Texture.init(allocator, "gui/panel.png", .{});
    }

    { // BUTTON
        button.texture = try gfx.Texture.init(allocator, "gui/button.png", .{});
    }

    { // SWITCHER
        switcher.texture = try gfx.Texture.init(allocator, "gui/switcher.png", .{});
    }

    { // SLIDER
        slider.texture = try gfx.Texture.init(allocator, "gui/slider.png", .{});
    }

    { // TEXT
        text.program = try gfx.Program.init(allocator, "text");
        text.uniform.vpsize = try gfx.Uniform.init(text.program, "vpsize");
        text.uniform.scale = try gfx.Uniform.init(text.program, "scale");
        text.uniform.pos = try gfx.Uniform.init(text.program, "pos");
        text.uniform.tex = try gfx.Uniform.init(text.program, "tex");
        text.uniform.color = try gfx.Uniform.init(text.program, "color");
        text.texture = try gfx.Texture.init(allocator, "gui/text.png", .{});
    }

    { // CURSOR
        cursor.texture = try gfx.Texture.init(allocator, "gui/cursor.png", .{});
    }
}

pub fn deinit() void {
    cursor.texture.deinit();

    text.texture.deinit();
    text.program.deinit();

    slider.texture.deinit();

    switcher.texture.deinit();

    button.texture.deinit();

    panel.texture.deinit();

    rect.program.deinit();
    rect.mesh.deinit();
    rect.buffer.deinit();

    line.program.deinit();
    line.mesh.deinit();
    line.vertex_buffer.deinit();
    line.color_buffer.deinit();

    terra.texture.dirt.deinit();
    terra.texture.grass.deinit();
    terra.texture.sand.deinit();
    terra.texture.stone.deinit();

    terra.program.deinit();
    for (terra.meshes) |item| if (item != null) item.?.deinit();
    for (terra.vertex_buffers) |item| if (item != null) item.?.deinit();
    for (terra.normal_buffers) |item| if (item != null) item.?.deinit();
}
