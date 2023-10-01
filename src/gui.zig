const std = @import("std");
const input = @import("input.zig");
const gl = @import("gl.zig");
const linmath = @import("linmath.zig");

pub const Color = @Vector(4, f32);
pub const Point = @Vector(2, i32);

pub const Rect = struct {
    min: Point,
    max: Point,

    pub fn size(self: Rect) Point {
        return self.max - self.min;
    }

    pub fn vector(self: Rect) @Vector(4, i32) {
        return .{
            self.min[0],
            self.min[1],
            self.max[0],
            self.max[1],
        };
    }

    pub fn scale(self: Rect, s: i32) Rect {
        return .{
            .min = .{ self.min[0] * s, self.min[1] * s },
            .max = .{ self.max[0] * s, self.max[1] * s },
        };
    }

    pub fn isAroundPoint(self: Rect, point: Point) bool {
        if (self.min[0] <= point[0] and self.max[0] >= point[0] and self.min[1] <= point[1] and self.max[1] >= point[1]) {
            return true;
        } else {
            return false;
        }
    }
};

pub const Control = union(enum) {
    pub const Alignment = struct {
        horizontal: enum { left, center, right } = .left,
        vertical: enum { bottom, center, top } = .bottom,

        pub fn transform(self: Alignment, rect: Rect, vpsize: Point) Rect {
            var result: Rect = rect;
            switch (self.horizontal) {
                .left => {},
                .center => {
                    result.min[0] = @divTrunc(vpsize[0], 2) + rect.min[0];
                    result.max[0] = @divTrunc(vpsize[0], 2) + rect.max[0];
                },
                .right => {
                    result.min[0] = vpsize[0] + rect.min[0];
                    result.max[0] = vpsize[0] + rect.max[0];
                },
            }
            switch (self.vertical) {
                .bottom => {},
                .center => {
                    result.min[1] = @divTrunc(vpsize[1], 2) + rect.min[1];
                    result.max[1] = @divTrunc(vpsize[1], 2) + rect.max[1];
                },
                .top => {
                    result.min[1] = vpsize[1] + rect.min[1];
                    result.max[1] = vpsize[1] + rect.max[1];
                },
            }
            return result;
        }
    };

    pub const Label = struct {
        pos: Point,
        size: Point,
        mesh: gl.Mesh,

        pub fn init(data: []const u16) !Label {
            var advance: i32 = 0;
            if (data.len > 512) return error.TextSizeOverflow;
            var i: usize = 0;
            for (data) |char| {
                if (char == ' ') {
                    advance += 3;
                    continue;
                }
                var glyph: Glyph = glyphs[0];
                for (glyphs) |pglyph| {
                    if (char == pglyph.code) glyph = pglyph;
                }

                vertices[i * 24 + (4 * 0) + 0] = @as(f32, @floatFromInt(advance)); // X
                vertices[i * 24 + (4 * 0) + 1] = 0.0; // Y
                vertices[i * 24 + (4 * 0) + 2] = @as(f32, @floatFromInt(glyph.pos)) / @as(f32, @floatFromInt(glyphs_width)); // U
                vertices[i * 24 + (4 * 0) + 3] = 1.0; // V

                vertices[i * 24 + (4 * 1) + 0] = @as(f32, @floatFromInt(advance)) + @as(f32, @floatFromInt(glyph.width)); // X
                vertices[i * 24 + (4 * 1) + 1] = 0.0; // Y
                vertices[i * 24 + (4 * 1) + 2] = (@as(f32, @floatFromInt(glyph.pos)) + @as(f32, @floatFromInt(glyph.width))) / @as(f32, @floatFromInt(glyphs_width)); // U
                vertices[i * 24 + (4 * 1) + 3] = 1.0; // V

                vertices[i * 24 + (4 * 2) + 0] = @as(f32, @floatFromInt(advance)) + @as(f32, @floatFromInt(glyph.width)); // X
                vertices[i * 24 + (4 * 2) + 1] = 8.0; // Y
                vertices[i * 24 + (4 * 2) + 2] = (@as(f32, @floatFromInt(glyph.pos)) + @as(f32, @floatFromInt(glyph.width))) / @as(f32, @floatFromInt(glyphs_width)); // U
                vertices[i * 24 + (4 * 2) + 3] = 0.0; // V

                vertices[i * 24 + (4 * 3) + 0] = @as(f32, @floatFromInt(advance)) + @as(f32, @floatFromInt(glyph.width)); // X
                vertices[i * 24 + (4 * 3) + 1] = 8.0; // Y
                vertices[i * 24 + (4 * 3) + 2] = (@as(f32, @floatFromInt(glyph.pos)) + @as(f32, @floatFromInt(glyph.width))) / @as(f32, @floatFromInt(glyphs_width)); // U
                vertices[i * 24 + (4 * 3) + 3] = 0.0; // V

                vertices[i * 24 + (4 * 4) + 0] = @as(f32, @floatFromInt(advance)); // X
                vertices[i * 24 + (4 * 4) + 1] = 8.0; // Y
                vertices[i * 24 + (4 * 4) + 2] = @as(f32, @floatFromInt(glyph.pos)) / @as(f32, @floatFromInt(glyphs_width)); // U
                vertices[i * 24 + (4 * 4) + 3] = 0.0; // V

                vertices[i * 24 + (4 * 5) + 0] = @as(f32, @floatFromInt(advance)); // X
                vertices[i * 24 + (4 * 5) + 1] = 0.0; // Y
                vertices[i * 24 + (4 * 5) + 2] = @as(f32, @floatFromInt(glyph.pos)) / @as(f32, @floatFromInt(glyphs_width)); // U
                vertices[i * 24 + (4 * 5) + 3] = 1.0; // V

                advance += glyph.width + 1;
                i += 1;
            }

            return Label{
                .pos = .{ 0, 0 },
                .size = .{ advance - 1, 8 },
                .mesh = try gl.Mesh.init(vertices[0..(i * 24)], &.{ 2, 2 }, .{ .usage = .static }),
            };
        }

        pub fn deinit(self: Label) void {
            self.mesh.deinit();
        }

        const Glyph = struct {
            code: u16,
            pos: i32,
            width: i32,
        };

        var vertices: [9216]f32 = [1]f32{0.0} ** 9216;

        const glyphs_width = 128;
        const glyphs = [_]Glyph{
            .{ .code = ' ', .pos = 0, .width = 3 },
            .{ .code = 'а', .pos = 3, .width = 3 },
            .{ .code = 'б', .pos = 6, .width = 3 },
            .{ .code = 'в', .pos = 9, .width = 3 },
            .{ .code = 'г', .pos = 12, .width = 3 },
            .{ .code = 'д', .pos = 15, .width = 5 },
            .{ .code = 'е', .pos = 20, .width = 3 },
            .{ .code = 'ё', .pos = 23, .width = 3 },
            .{ .code = 'ж', .pos = 26, .width = 5 },
            .{ .code = 'з', .pos = 31, .width = 3 },
            .{ .code = 'и', .pos = 34, .width = 4 },
            .{ .code = 'й', .pos = 38, .width = 4 },
            .{ .code = 'к', .pos = 42, .width = 3 },
            .{ .code = 'л', .pos = 45, .width = 3 },
            .{ .code = 'м', .pos = 48, .width = 5 },
            .{ .code = 'н', .pos = 53, .width = 3 },
            .{ .code = 'о', .pos = 56, .width = 3 },
            .{ .code = 'п', .pos = 59, .width = 3 },
            .{ .code = 'р', .pos = 62, .width = 3 },
            .{ .code = 'с', .pos = 65, .width = 3 },
            .{ .code = 'т', .pos = 68, .width = 3 },
            .{ .code = 'у', .pos = 71, .width = 3 },
            .{ .code = 'ф', .pos = 74, .width = 5 },
            .{ .code = 'х', .pos = 79, .width = 3 },
            .{ .code = 'ц', .pos = 82, .width = 4 },
            .{ .code = 'ч', .pos = 86, .width = 3 },
            .{ .code = 'ш', .pos = 89, .width = 5 },
            .{ .code = 'щ', .pos = 94, .width = 5 },
            .{ .code = 'ъ', .pos = 99, .width = 4 },
            .{ .code = 'ы', .pos = 103, .width = 5 },
            .{ .code = 'ь', .pos = 108, .width = 3 },
            .{ .code = 'э', .pos = 111, .width = 4 },
            .{ .code = 'ю', .pos = 115, .width = 5 },
            .{ .code = 'я', .pos = 120, .width = 3 },
        };
    };

    pub const Button = struct {
        rect: Rect,
        alignment: Alignment = .{},
        state: enum { empty, focus, press } = .empty,
        label: Label,
    };

    label: Label,
    button: Button,
};

pub const Controls = std.ArrayList(Control);
pub const ControlId = usize;

pub const State = struct {
    controls: std.ArrayList(Control),
    vpsize: Point,
    scale: i32,
    render: struct {
        rect: struct {
            mesh: gl.Mesh,
        },
        font: struct {
            texture: gl.Texture,
        },
        label: struct {
            program: gl.Program,
        },
        button: struct {
            program: gl.Program,
            texture: struct {
                empty: gl.Texture,
                focus: gl.Texture,
                press: gl.Texture,
            },
        },
    },

    pub fn init(allocator: std.mem.Allocator, vpsize: Point) !State {
        const label_vertex = try gl.Shader.initFormFile(
            allocator,
            "data/shader/gui/label/vertex.glsl",
            gl.Shader.Type.vertex,
        );
        defer label_vertex.deinit();

        const label_fragment = try gl.Shader.initFormFile(
            allocator,
            "data/shader/gui/label/fragment.glsl",
            gl.Shader.Type.fragment,
        );
        defer label_fragment.deinit();

        const button_vertex = try gl.Shader.initFormFile(
            allocator,
            "data/shader/gui/button/vertex.glsl",
            gl.Shader.Type.vertex,
        );
        defer button_vertex.deinit();

        const button_fragment = try gl.Shader.initFormFile(
            allocator,
            "data/shader/gui/button/fragment.glsl",
            gl.Shader.Type.fragment,
        );
        defer button_fragment.deinit();

        const state = State{
            .controls = Controls.init(allocator),
            .vpsize = vpsize,
            .scale = 4,
            .render = .{
                .rect = .{
                    .mesh = try gl.Mesh.init(
                        &.{ 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0 },
                        &.{2},
                        .{},
                    ),
                },
                .font = .{
                    .texture = try gl.Texture.init("data/gui/font.png"),
                },
                .label = .{
                    .program = try gl.Program.init(
                        allocator,
                        &.{ label_vertex, label_fragment },
                        &.{ "matrix", "color" },
                    ),
                },
                .button = .{
                    .program = try gl.Program.init(
                        allocator,
                        &.{ button_vertex, button_fragment },
                        &.{ "matrix", "scale", "rect", "texsize" },
                    ),
                    .texture = .{
                        .empty = try gl.Texture.init("data/gui/button/empty.png"),
                        .focus = try gl.Texture.init("data/gui/button/focus.png"),
                        .press = try gl.Texture.init("data/gui/button/press.png"),
                    },
                },
            },
        };
        std.log.debug("gui init state = {}", .{state});
        return state;
    }

    pub fn deinit(self: State) void {
        std.log.debug("gui deinit state = {}", .{self});
        self.render.button.texture.press.deinit();
        self.render.button.texture.focus.deinit();
        self.render.button.texture.empty.deinit();
        self.render.button.program.deinit();
        self.render.font.texture.deinit();
        self.render.label.program.deinit();
        self.render.rect.mesh.deinit();
        for (self.controls.items) |control| {
            switch (control) {
                .label => control.label.deinit(),
                .button => control.button.label.deinit(),
            }
        }
        self.controls.deinit();
    }

    pub fn addControl(self: *State, control: Control) !ControlId {
        try self.controls.append(control);
        return self.controls.items.len - 1;
    }
};

pub const RenderSystem = struct {
    pub fn draw(state: State) void {
        for (state.controls.items) |control| {
            switch (control) {
                .label => {},
                .button => |button| {
                    const pos = button.alignment.transform(button.rect.scale(state.scale), state.vpsize).min;
                    const size = button.rect.scale(state.scale).size();
                    const matrix = linmath.Mat{
                        .{
                            @as(f32, @floatFromInt(size[0])) / @as(f32, @floatFromInt(state.vpsize[0])) * 2.0,
                            0.0,
                            0.0,
                            -1.0 + @as(f32, @floatFromInt(pos[0])) / @as(f32, @floatFromInt(state.vpsize[0])) * 2.0,
                        },
                        .{
                            0.0,
                            @as(f32, @floatFromInt(size[1])) / @as(f32, @floatFromInt(state.vpsize[1])) * 2.0,
                            0.0,
                            -1.0 + @as(f32, @floatFromInt(pos[1])) / @as(f32, @floatFromInt(state.vpsize[1])) * 2.0,
                        },
                        .{ 0.0, 0.0, 1.0, 0.0 },
                        .{ 0.0, 0.0, 0.0, 1.0 },
                    };
                    state.render.button.program.use();
                    state.render.button.program.setUniform(0, matrix);
                    state.render.button.program.setUniform(1, state.scale);
                    state.render.button.program.setUniform(2, button.alignment.transform(button.rect.scale(state.scale), state.vpsize).vector());
                    switch (button.state) {
                        .empty => {
                            state.render.button.texture.empty.use();
                            state.render.button.program.setUniform(3, state.render.button.texture.empty.size);
                        },
                        .focus => {
                            state.render.button.texture.focus.use();
                            state.render.button.program.setUniform(3, state.render.button.texture.focus.size);
                        },
                        .press => {
                            state.render.button.texture.press.use();
                            state.render.button.program.setUniform(3, state.render.button.texture.press.size);
                        },
                    }
                    state.render.rect.mesh.draw();

                    const label_pos = pos + (button.rect.size() - button.label.size) * Point{ @divTrunc(state.scale, 2), @divTrunc(state.scale, 2) };
                    const matrix_label = linmath.Mat{
                        .{
                            @as(f32, @floatFromInt(state.scale)) / @as(f32, @floatFromInt(state.vpsize[0])) * 2.0,
                            0.0,
                            0.0,
                            @as(f32, @floatFromInt(label_pos[0])) / @as(f32, @floatFromInt(state.vpsize[0])) * 2.0 - 1.0,
                        },
                        .{
                            0.0,
                            @as(f32, @floatFromInt(state.scale)) / @as(f32, @floatFromInt(state.vpsize[1])) * 2.0,
                            0.0,
                            @as(f32, @floatFromInt(label_pos[1])) / @as(f32, @floatFromInt(state.vpsize[1])) * 2.0 - 1.0,
                        },
                        .{ 0.0, 0.0, 1.0, 0.0 },
                        .{ 0.0, 0.0, 0.0, 1.0 },
                    };
                    state.render.label.program.use();
                    state.render.label.program.setUniform(0, matrix_label);
                    state.render.label.program.setUniform(1, Color{ 1.0, 1.0, 1.0, 1.0 });
                    state.render.font.texture.use();
                    button.label.mesh.draw();
                },
            }
        }
    }
};

pub const InputSystem = struct {
    pub fn process(state: *State, input_state: input.State) void {
        for (state.*.controls.items) |*control| {
            switch (control.*) {
                .button => |*button| {
                    if (button.alignment.transform(button.rect.scale(state.scale), state.vpsize).isAroundPoint(input_state.cursor.pos)) {
                        button.state = .focus;

                        if (button.state == .focus and input_state.mouse.buttons[1]) {
                            button.state = .press;
                        }
                    } else {
                        button.state = .empty;
                    }
                },
                .label => {},
            }
        }
    }
};

pub const Event = union(enum) {
    press: usize,
    unpress: usize,
    none,
};

pub const EventSystem = struct {
    pub fn process(state: State, input_state: input.State, event: input.Event) Event {
        switch (event) {
            .mouse_button_down => |mouse_button_code| if (mouse_button_code == 1) {
                for (state.controls.items, 0..) |control, i| {
                    switch (control) {
                        .button => |button| {
                            if (button.alignment.transform(
                                button.rect.scale(state.scale),
                                state.vpsize,
                            ).isAroundPoint(input_state.cursor.pos)) {
                                return .{ .press = i };
                            }
                        },
                        else => {},
                    }
                }
            },
            .mouse_button_up => |mouse_button_code| if (mouse_button_code == 1) {
                for (state.controls.items, 0..) |control, i| {
                    switch (control) {
                        .button => |button| {
                            if (button.alignment.transform(
                                button.rect.scale(state.scale),
                                state.vpsize,
                            ).isAroundPoint(input_state.cursor.pos)) {
                                return .{ .unpress = i };
                            }
                        },
                        else => {},
                    }
                }
            },
            else => {},
        }
        return .none;
    }
};
