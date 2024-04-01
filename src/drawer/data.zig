const std = @import("std");

const Allocator = std.mem.Allocator;

const gfx = @import("../gfx.zig");
const world = @import("../world.zig");
const gui = @import("../gui.zig");

pub const terra = struct {
    pub const chunk = struct {
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
};

pub const entity = struct {
    pub const actor = struct {
        pub var vertex_buffer: gfx.Buffer = undefined;
        pub var normal_buffer: gfx.Buffer = undefined;
        pub var mesh: gfx.Mesh = undefined;
        pub var program: gfx.Program = undefined;
        pub const uniform = struct {};
    };

    pub const bullet = struct {
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
        @memset(terra.chunk.normal_buffers[0..], null);
        @memset(terra.chunk.vertex_buffers[0..], null);
        @memset(terra.chunk.meshes[0..], null);

        terra.chunk.program = try gfx.Program.init(allocator, "world/terra/chunk");

        terra.chunk.uniform.model = try gfx.Uniform.init(terra.chunk.program, "model");
        terra.chunk.uniform.view = try gfx.Uniform.init(terra.chunk.program, "view");
        terra.chunk.uniform.proj = try gfx.Uniform.init(terra.chunk.program, "proj");

        terra.chunk.uniform.light.color = try gfx.Uniform.init(terra.chunk.program, "light.color");
        terra.chunk.uniform.light.direction = try gfx.Uniform.init(terra.chunk.program, "light.direction");
        terra.chunk.uniform.light.ambient = try gfx.Uniform.init(terra.chunk.program, "light.ambient");
        terra.chunk.uniform.light.diffuse = try gfx.Uniform.init(terra.chunk.program, "light.diffuse");
        terra.chunk.uniform.light.specular = try gfx.Uniform.init(terra.chunk.program, "light.specular");

        terra.chunk.uniform.chunk.width = try gfx.Uniform.init(terra.chunk.program, "chunk.width");
        terra.chunk.uniform.chunk.pos = try gfx.Uniform.init(terra.chunk.program, "chunk.pos");

        terra.chunk.texture.dirt = try gfx.Texture.init(allocator, "world/terra/dirt.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
        terra.chunk.texture.grass = try gfx.Texture.init(allocator, "world/terra/grass.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
        terra.chunk.texture.sand = try gfx.Texture.init(allocator, "world/terra/sand.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
        terra.chunk.texture.stone = try gfx.Texture.init(allocator, "world/terra/stone.png", .{ .min_filter = .nearest_mipmap_nearest, .mipmap = true });
    }

    { // ENTITY
        { // ACTOR

        }

        { // BULLETS
            entity.bullet.vertex_buffer = try gfx.Buffer.init(.{
                .name = "world entity bullet vertex",
                .target = .vbo,
                .datatype = .f32,
                .vertsize = 4,
                .usage = .dynamic_draw,
            });
            entity.bullet.vertex_buffer.data(world.entity.bullets.getPosBytes());

            entity.bullet.mesh = try gfx.Mesh.init(.{
                .name = "world entity bullet mesh",
                .buffers = &.{entity.bullet.vertex_buffer},
                .vertcnt = world.entity.bullets.len,
                .drawmode = .points,
            });

            entity.bullet.program = try gfx.Program.init(allocator, "world/entity/bullet");
            entity.bullet.uniform.model = try gfx.Uniform.init(entity.bullet.program, "model");
            entity.bullet.uniform.view = try gfx.Uniform.init(entity.bullet.program, "view");
            entity.bullet.uniform.proj = try gfx.Uniform.init(entity.bullet.program, "proj");
        }
    }

    { // SHAPE
        { // LINE
            shape.line.vertex_buffer = try gfx.Buffer.init(.{
                .name = "world shape line vertex",
                .target = .vbo,
                .datatype = .f32,
                .vertsize = 4,
                .usage = .static_draw,
            });
            shape.line.vertex_buffer.data(std.mem.sliceAsBytes(world.shape.lines.getVertexBytes()));

            shape.line.color_buffer = try gfx.Buffer.init(.{
                .name = "world shape line vertex",
                .target = .vbo,
                .datatype = .f32,
                .vertsize = 4,
                .usage = .static_draw,
            });
            shape.line.color_buffer.data(std.mem.sliceAsBytes(world.shape.lines.getColorBytes()));

            shape.line.mesh = try gfx.Mesh.init(.{
                .name = "world shape line mesh",
                .buffers = &.{ shape.line.vertex_buffer, shape.line.color_buffer },
                .vertcnt = world.shape.lines.len,
                .drawmode = .lines,
            });

            shape.line.program = try gfx.Program.init(allocator, "world/shape/line");
            shape.line.uniform.model = try gfx.Uniform.init(shape.line.program, "model");
            shape.line.uniform.view = try gfx.Uniform.init(shape.line.program, "view");
            shape.line.uniform.proj = try gfx.Uniform.init(shape.line.program, "proj");
        }
    }

    { // RECT
        rect.buffer = try gfx.Buffer.init(.{
            .name = "gui rect",
            .target = .vbo,
            .datatype = .u8,
            .vertsize = 2,
            .usage = .static_draw,
        });
        rect.buffer.data(&.{ 0, 0, 0, 1, 1, 0, 1, 1 });
        rect.mesh = try gfx.Mesh.init(.{
            .name = "gui rect",
            .buffers = &.{rect.buffer},
            .vertcnt = 4,
            .drawmode = .triangle_strip,
        });

        rect.program = try gfx.Program.init(allocator, "gui/rect");
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
        text.program = try gfx.Program.init(allocator, "gui/text");
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
    { // GUI
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
    }

    { // WORLD
        { // SHAPE
            shape.line.program.deinit();
            shape.line.mesh.deinit();
            shape.line.vertex_buffer.deinit();
            shape.line.color_buffer.deinit();
        }

        { // ENTITY
            entity.bullet.program.deinit();
            entity.bullet.mesh.deinit();
            entity.bullet.vertex_buffer.deinit();
        }

        { // TERRA
            terra.chunk.texture.dirt.deinit();
            terra.chunk.texture.grass.deinit();
            terra.chunk.texture.sand.deinit();
            terra.chunk.texture.stone.deinit();
            terra.chunk.program.deinit();
            for (terra.chunk.meshes) |item| if (item != null) item.?.deinit();
            for (terra.chunk.vertex_buffers) |item| if (item != null) item.?.deinit();
            for (terra.chunk.normal_buffers) |item| if (item != null) item.?.deinit();
        }
    }
}
