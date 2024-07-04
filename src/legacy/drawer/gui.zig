const std = @import("std");
const log = std.log.scoped(.drawerGui);
const gfx = @import("../gfx.zig");
const gui = @import("../gui.zig");
const window = @import("../window.zig");

const Allocator = std.mem.Allocator;

const _data = struct {
    const rect = struct {
        var buffer: gfx.Buffer = undefined;
        var mesh: gfx.Mesh = undefined;
        var program: gfx.Program = undefined;
        const uniform = struct {
            var vpsize: gfx.Uniform = undefined;
            var scale: gfx.Uniform = undefined;
            var rect: gfx.Uniform = undefined;
            var texrect: gfx.Uniform = undefined;
        };
    };

    const panel = struct {
        var texture: gfx.Texture = undefined;
    };

    const button = struct {
        var texture: gfx.Texture = undefined;
    };

    const switcher = struct {
        var texture: gfx.Texture = undefined;
    };

    const slider = struct {
        var texture: gfx.Texture = undefined;
    };

    const text = struct {
        var program: gfx.Program = undefined;
        const uniform = struct {
            var vpsize: gfx.Uniform = undefined;
            var scale: gfx.Uniform = undefined;
            var pos: gfx.Uniform = undefined;
            var tex: gfx.Uniform = undefined;
            var color: gfx.Uniform = undefined;
        };
        var texture: gfx.Texture = undefined;
    };

    const cursor = struct {
        var texture: gfx.Texture = undefined;
    };
};

pub fn init(allocator: Allocator) !void {
    _data.rect.buffer = try gfx.Buffer.init(.{
        .name = "gui rect vertex",
        .target = .vbo,
        .datatype = .u8,
        .vertsize = 2,
        .usage = .static_draw,
    });
    _data.rect.buffer.data(&.{ 0, 0, 0, 1, 1, 0, 1, 1 });
    _data.rect.mesh = try gfx.Mesh.init(.{
        .name = "gui rect mesh",
        .buffers = &.{_data.rect.buffer},
        .vertcnt = 4,
        .drawmode = .triangle_strip,
    });
    _data.rect.program = try gfx.Program.init("gui/rect");
    _data.rect.uniform.vpsize = try gfx.Uniform.init(_data.rect.program, "vpsize");
    _data.rect.uniform.scale = try gfx.Uniform.init(_data.rect.program, "scale");
    _data.rect.uniform.rect = try gfx.Uniform.init(_data.rect.program, "rect");
    _data.rect.uniform.texrect = try gfx.Uniform.init(_data.rect.program, "texrect");

    _data.panel.texture = try gfx.Texture.init(allocator, "gui/panel.png", .{});

    _data.button.texture = try gfx.Texture.init(allocator, "gui/button.png", .{});

    _data.switcher.texture = try gfx.Texture.init(allocator, "gui/switcher.png", .{});

    _data.slider.texture = try gfx.Texture.init(allocator, "gui/slider.png", .{});

    _data.text.program = try gfx.Program.init("gui/text");
    _data.text.uniform.color = try gfx.Uniform.init(_data.text.program, "color");
    _data.text.uniform.pos = try gfx.Uniform.init(_data.text.program, "pos");
    _data.text.uniform.scale = try gfx.Uniform.init(_data.text.program, "scale");
    _data.text.uniform.tex = try gfx.Uniform.init(_data.text.program, "tex");
    _data.text.uniform.vpsize = try gfx.Uniform.init(_data.text.program, "vpsize");
    _data.text.texture = try gfx.Texture.init(allocator, "gui/text.png", .{});

    _data.cursor.texture = try gfx.Texture.init(allocator, "gui/cursor.png", .{});
}

pub fn deinit() void {
    _data.cursor.texture.deinit();
    _data.text.texture.deinit();
    _data.text.program.deinit();
    _data.slider.texture.deinit();
    _data.switcher.texture.deinit();
    _data.button.texture.deinit();
    _data.panel.texture.deinit();
    _data.rect.program.deinit();
    _data.rect.mesh.deinit();
    _data.rect.buffer.deinit();
}

pub fn draw() void {
    drawRect();
    drawPanel();
    drawButton();
    drawSwitcher();
    drawSlider();
    drawText();
    drawCursor();
}

fn drawRect() void {
    _data.rect.program.use();
    _data.rect.uniform.vpsize.set(window.size);
    _data.rect.uniform.scale.set(gui.scale);
}

fn drawPanel() void {
    _data.panel.texture.bind(0);
    for (gui.panels.items) |item| {
        if (gui.menus.items[item.menu].show) {
            _data.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
            _data.rect.uniform.texrect.set(@Vector(4, i32){
                0,
                0,
                @intCast(_data.panel.texture.size[0]),
                @intCast(_data.panel.texture.size[1]),
            });
            _data.rect.mesh.draw();
        }
    }
}

fn drawButton() void {
    _data.button.texture.bind(0);
    for (gui.buttons.items) |item| {
        if (gui.menus.items[item.menu].show) {
            _data.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
            switch (item.state) {
                .empty => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 8, 8 }),
                .focus => _data.rect.uniform.texrect.set(@Vector(4, i32){ 8, 0, 16, 8 }),
                .press => _data.rect.uniform.texrect.set(@Vector(4, i32){ 16, 0, 24, 8 }),
            }
            _data.rect.mesh.draw();
        }
    }
}

fn drawSwitcher() void {
    _data.switcher.texture.bind(0);
    for (gui.switchers.items) |item| {
        if (gui.menus.items[item.menu].show) {
            _data.rect.uniform.rect.set(
                item.alignment.transform(gui.Rect{
                    .min = .{
                        item.pos[0] * gui.scale,
                        item.pos[1] * gui.scale,
                    },
                    .max = .{
                        (item.pos[0] + 12) * gui.scale,
                        (item.pos[1] + 8) * gui.scale,
                    },
                }, window.size).vector(),
            );
            switch (item.state) {
                .empty => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 6, 8 }),
                .focus => _data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 0, 12, 8 }),
                .press => _data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 0, 18, 8 }),
            }
            _data.rect.mesh.draw();

            _data.rect.uniform.rect.set(
                item.alignment.transform(gui.Rect{
                    .min = .{
                        (item.pos[0] + 2 + @as(i32, @intFromBool(item.status)) * 4) * gui.scale,
                        (item.pos[1]) * gui.scale,
                    },
                    .max = .{
                        (item.pos[0] + 6 + @as(i32, @intFromBool(item.status)) * 4) * gui.scale,
                        (item.pos[1] + 8) * gui.scale,
                    },
                }, window.size).vector(),
            );
            switch (item.state) {
                .empty => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 8, 4, 16 }),
                .focus => _data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 8, 10, 16 }),
                .press => _data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 8, 16, 16 }),
            }
            _data.rect.mesh.draw();
        }
    }
}

fn drawSlider() void {
    _data.slider.texture.bind(0);
    _data.rect.uniform.vpsize.set(window.size);
    _data.rect.uniform.scale.set(gui.scale);
    for (gui.sliders.items) |item| {
        if (gui.menus.items[item.menu].show) {
            _data.rect.uniform.rect.set(item.alignment.transform(item.rect.scale(gui.scale), window.size).vector());
            switch (item.state) {
                .empty => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 6, 8 }),
                .focus => _data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 0, 12, 8 }),
                .press => _data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 0, 18, 8 }),
            }
            _data.rect.mesh.draw();

            const len: f32 = @floatFromInt(item.rect.scale(gui.scale).size()[0] - 6 * gui.scale);
            const pos: i32 = @intFromFloat(item.value * len);
            _data.rect.uniform.rect.set(
                item.alignment.transform(gui.Rect{
                    .min = item.rect.min * gui.Size{ gui.scale, gui.scale } + gui.Pos{ pos, 0 },
                    .max = .{
                        item.rect.min[0] * gui.scale + pos + 6 * gui.scale,
                        item.rect.max[1] * gui.scale,
                    },
                }, window.size).vector(),
            );
            switch (item.state) {
                .empty => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 8, 6, 16 }),
                .focus => _data.rect.uniform.texrect.set(@Vector(4, i32){ 6, 8, 12, 16 }),
                .press => _data.rect.uniform.texrect.set(@Vector(4, i32){ 12, 8, 18, 16 }),
            }
            _data.rect.mesh.draw();
        }
    }
}

fn drawText() void {
    _data.text.program.use();
    _data.text.texture.bind(0);
    _data.text.uniform.vpsize.set(window.size);
    _data.text.uniform.scale.set(gui.scale);
    _data.text.uniform.color.set(gui.Color{ 1.0, 1.0, 1.0, 1.0 });
    for (gui.texts.items) |item| {
        if (gui.menus.items[item.menu].show) {
            const pos = item.alignment.transform(item.rect.scale(gui.scale), window.size).min;
            var offset: i32 = 0;
            for (item.data) |cid| {
                if (cid == ' ') {
                    offset += 3 * gui.scale;
                    continue;
                }
                _data.text.uniform.pos.set(gui.Pos{ pos[0] + offset, pos[1] });
                _data.text.uniform.tex.set(gui.Pos{ gui.font.chars[cid].pos, gui.font.chars[cid].width });
                _data.rect.mesh.draw();
                offset += (gui.font.chars[cid].width + 1) * gui.scale;
            }
        }
    }
}

fn drawCursor() void {
    _data.rect.program.use();
    _data.cursor.texture.bind(0);
    const p1 = 4 * gui.scale - @divTrunc(gui.scale, 2);
    const p2 = 3 * gui.scale + @divTrunc(gui.scale, 2);
    _data.rect.uniform.rect.set((gui.Rect{
        .min = gui.cursor.pos - gui.Pos{ p1, p1 },
        .max = gui.cursor.pos + gui.Pos{ p2, p2 },
    }).vector());
    switch (gui.cursor.press) {
        false => _data.rect.uniform.texrect.set(@Vector(4, i32){ 0, 0, 7, 7 }),
        true => _data.rect.uniform.texrect.set(@Vector(4, i32){ 7, 0, 14, 7 }),
    }
    _data.rect.mesh.draw();
}
