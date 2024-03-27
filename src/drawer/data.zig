const std = @import("std");

const Allocator = std.mem.Allocator;

const gfx = @import("../gfx.zig");
const world = @import("../world.zig");
const gui = @import("../gui.zig");

pub const terra = struct {
    const w = world.terra.Chunk.w;

    const xoffset = (w + 1) * (w + 1) * w * 0;
    const yoffset = (w + 1) * (w + 1) * w * 1;
    const zoffset = (w + 1) * (w + 1) * w * 2;

    pub const edge = [12]u32{
        xoffset + w,
        yoffset + 1,
        xoffset,
        yoffset,

        xoffset + (w + 1) * w + w,
        yoffset + (w + 1) * w + 1,
        xoffset + (w + 1) * w,
        yoffset + (w + 1) * w,

        zoffset + w + 1,
        zoffset + w + 1 + 1,
        zoffset + 1,
        zoffset,
    };

    pub var pos_buffer: gfx.Buffer = undefined;
    pub var nrm_buffers: [world.terra.w * world.terra.w * world.terra.h]?gfx.Buffer = undefined;
    pub var ebo_buffers: [world.terra.w * world.terra.w * world.terra.h]?gfx.Buffer = undefined;
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
    pub var texture: gfx.Texture = undefined;
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
        const w = world.terra.Chunk.w;
        const pos_buffer_vertsize = 3;
        const s = struct {
            var pos_buffer_data = [1]f32{0.0} ** ((w + 1) * (w + 1) * w * pos_buffer_vertsize * 3);
        };

        // x space
        for (0..(w + 1)) |z| {
            for (0..(w + 1)) |y| {
                for (0..(w)) |x| {
                    const offset = (x + y * (w) + z * (w * (w + 1)));
                    s.pos_buffer_data[(terra.xoffset + offset) * pos_buffer_vertsize + 0] = @as(f32, @floatFromInt(x)) + 0.5;
                    s.pos_buffer_data[(terra.xoffset + offset) * pos_buffer_vertsize + 1] = @as(f32, @floatFromInt(y));
                    s.pos_buffer_data[(terra.xoffset + offset) * pos_buffer_vertsize + 2] = @as(f32, @floatFromInt(z));
                }
            }
        }

        // y space
        for (0..(w + 1)) |z| {
            for (0..(w)) |y| {
                for (0..(w + 1)) |x| {
                    const offset = (x + y * (w + 1) + z * (w * (w + 1)));
                    s.pos_buffer_data[(terra.yoffset + offset) * pos_buffer_vertsize + 0] = @as(f32, @floatFromInt(x));
                    s.pos_buffer_data[(terra.yoffset + offset) * pos_buffer_vertsize + 1] = @as(f32, @floatFromInt(y)) + 0.5;
                    s.pos_buffer_data[(terra.yoffset + offset) * pos_buffer_vertsize + 2] = @as(f32, @floatFromInt(z));
                }
            }
        }

        // z space
        for (0..(w)) |z| {
            for (0..(w + 1)) |y| {
                for (0..(w + 1)) |x| {
                    const offset = (x + y * (w + 1) + z * ((w + 1) * (w + 1)));
                    s.pos_buffer_data[(terra.zoffset + offset) * pos_buffer_vertsize + 0] = @as(f32, @floatFromInt(x));
                    s.pos_buffer_data[(terra.zoffset + offset) * pos_buffer_vertsize + 1] = @as(f32, @floatFromInt(y));
                    s.pos_buffer_data[(terra.zoffset + offset) * pos_buffer_vertsize + 2] = @as(f32, @floatFromInt(z)) + 0.5;
                }
            }
        }

        terra.pos_buffer = try gfx.Buffer.init(.{
            .name = "terra vertex",
            .target = .vbo,
            .datatype = .f32,
            .vertsize = pos_buffer_vertsize,
            .usage = .static_draw,
        });
        terra.pos_buffer.data(std.mem.sliceAsBytes(s.pos_buffer_data[0..]));

        @memset(terra.nrm_buffers[0..], null);
        @memset(terra.nrm_buffers[0..], null);
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
        terra.texture = try gfx.Texture.init(allocator, "grass.png");
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
        panel.texture = try gfx.Texture.init(allocator, "panel.png");
    }

    { // BUTTON
        button.texture = try gfx.Texture.init(allocator, "button.png");
    }

    { // SWITCHER
        switcher.texture = try gfx.Texture.init(allocator, "switcher.png");
    }

    { // SLIDER
        slider.texture = try gfx.Texture.init(allocator, "slider.png");
    }

    { // TEXT
        text.program = try gfx.Program.init(allocator, "text");
        text.uniform.vpsize = try gfx.Uniform.init(text.program, "vpsize");
        text.uniform.scale = try gfx.Uniform.init(text.program, "scale");
        text.uniform.pos = try gfx.Uniform.init(text.program, "pos");
        text.uniform.tex = try gfx.Uniform.init(text.program, "tex");
        text.uniform.color = try gfx.Uniform.init(text.program, "color");
        text.texture = try gfx.Texture.init(allocator, "text.png");
    }

    { // CURSOR
        cursor.texture = try gfx.Texture.init(allocator, "cursor.png");
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

    terra.texture.deinit();
    terra.program.deinit();
    for (terra.meshes) |item| if (item != null) item.?.deinit();
    for (terra.ebo_buffers) |item| if (item != null) item.?.deinit();
    for (terra.nrm_buffers) |item| if (item != null) item.?.deinit();
    terra.pos_buffer.deinit();
}
