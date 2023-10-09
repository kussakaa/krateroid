const std = @import("std");
const input = @import("input.zig");
const gl = @import("gl.zig");
const linmath = @import("linmath.zig");
const Mat = linmath.Mat;
const Vec = linmath.Vec;

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

pub const Alignment = struct {
    horizontal: enum { left, center, right } = .left,
    vertical: enum { bottom, center, top } = .top,

    pub fn transform(self: Alignment, obj: anytype, vpsize: Point) @TypeOf(obj) {
        return switch (comptime @TypeOf(obj)) {
            Point => self.transformPoint(obj, vpsize),
            Rect => .{
                .min = self.transformPoint(obj.min, vpsize),
                .max = self.transformPoint(obj.max, vpsize),
            },
            else => @compileError("invalid type for gui.Alignment.transform()"),
        };
    }

    pub fn transformPoint(self: Alignment, point: Point, vpsize: Point) Point {
        var result: Point = point;
        switch (self.horizontal) {
            .left => {},
            .center => result[0] = @divTrunc(vpsize[0], 2) + point[0],
            .right => result[0] = vpsize[0] + point[0],
        }
        switch (self.vertical) {
            .top => {},
            .center => result[1] = @divTrunc(vpsize[1], 2) + point[1],
            .bottom => result[1] = vpsize[1] + point[1],
        }
        return result;
    }
};

pub const Font = struct {
    pub const file = "data/gui/text/font.png";
    pub const chars = [_]Char{
        .{ .code = ' ' },
        .{ .code = '!', .pos = 3, .width = 1 },
        .{ .code = '"', .pos = 4 },
        .{ .code = '#', .pos = 7, .width = 5 },
        .{ .code = '$', .pos = 12 },
        .{ .code = '\'', .pos = 15, .width = 1 },
        .{ .code = '(', .pos = 16, .width = 1 },
        .{ .code = ')', .pos = 18, .width = 1 },
        .{ .code = '*', .pos = 20 },
        .{ .code = '+', .pos = 23 },
        .{ .code = ',', .pos = 26, .width = 1 },
        .{ .code = '-', .pos = 27, .width = 2 },
        .{ .code = '.', .pos = 29, .width = 1 },
        .{ .code = '/', .pos = 30 },
        .{ .code = '0', .pos = 33 },
        .{ .code = '1', .pos = 36 },
        .{ .code = '2', .pos = 38 },
        .{ .code = '3', .pos = 41 },
        .{ .code = '4', .pos = 44 },
        .{ .code = '5', .pos = 47 },
        .{ .code = '6', .pos = 50 },
        .{ .code = '7', .pos = 53 },
        .{ .code = '8', .pos = 56 },
        .{ .code = '9', .pos = 59 },
        .{ .code = ':', .pos = 62, .width = 1 },
        .{ .code = ';', .pos = 63, .width = 1 },
        .{ .code = '<', .pos = 64 },
        .{ .code = '=', .pos = 67 },
        .{ .code = '>', .pos = 70 },
        .{ .code = '?', .pos = 73 },
        .{ .code = '@', .pos = 76, .width = 5 },
        .{ .code = 'a', .pos = 81 },
        .{ .code = 'b', .pos = 84 },
        .{ .code = 'c', .pos = 87 },
        .{ .code = 'd', .pos = 90 },
        .{ .code = 'e', .pos = 93 },
        .{ .code = 'f', .pos = 96 },
        .{ .code = 'g', .pos = 99 },
        .{ .code = 'h', .pos = 102 },
        .{ .code = 'i', .pos = 105, .width = 1 },
        .{ .code = 'j', .pos = 106 },
        .{ .code = 'k', .pos = 109 },
        .{ .code = 'l', .pos = 112 },
        .{ .code = 'm', .pos = 115 },
        .{ .code = 'n', .pos = 120 },
        .{ .code = 'o', .pos = 124 },
        .{ .code = 'p', .pos = 127 },
        .{ .code = 'q', .pos = 130 },
        .{ .code = 'r', .pos = 133 },
        .{ .code = 's', .pos = 136 },
        .{ .code = 't', .pos = 139 },
        .{ .code = 'u', .pos = 142 },
        .{ .code = 'v', .pos = 145 },
        .{ .code = 'w', .pos = 148 },
        .{ .code = 'x', .pos = 153 },
        .{ .code = 'y', .pos = 156 },
        .{ .code = 'z', .pos = 159 },
        .{ .code = '[', .pos = 162, .width = 2 },
        .{ .code = '\\', .pos = 164, .width = 3 },
        .{ .code = ']', .pos = 167, .width = 2 },
        .{ .code = '^', .pos = 169 },
        .{ .code = '_', .pos = 172 },
        .{ .code = 'а', .pos = 175 },
        .{ .code = 'б', .pos = 178 },
        .{ .code = 'в', .pos = 181 },
        .{ .code = 'г', .pos = 184 },
        .{ .code = 'д', .pos = 187, .width = 5 },
        .{ .code = 'е', .pos = 192 },
        .{ .code = 'ё', .pos = 195 },
        .{ .code = 'ж', .pos = 198, .width = 5 },
        .{ .code = 'з', .pos = 203 },
        .{ .code = 'и', .pos = 206, .width = 4 },
        .{ .code = 'й', .pos = 210, .width = 4 },
        .{ .code = 'к', .pos = 214 },
        .{ .code = 'л', .pos = 217 },
        .{ .code = 'м', .pos = 220, .width = 5 },
        .{ .code = 'н', .pos = 225 },
        .{ .code = 'о', .pos = 228 },
        .{ .code = 'п', .pos = 231 },
        .{ .code = 'р', .pos = 234 },
        .{ .code = 'с', .pos = 237 },
        .{ .code = 'т', .pos = 240 },
        .{ .code = 'у', .pos = 243 },
        .{ .code = 'ф', .pos = 246, .width = 5 },
        .{ .code = 'х', .pos = 251 },
        .{ .code = 'ц', .pos = 254 },
        .{ .code = 'ч', .pos = 257 },
        .{ .code = 'ш', .pos = 260, .width = 5 },
        .{ .code = 'щ', .pos = 265, .width = 5 },
        .{ .code = 'ъ', .pos = 270, .width = 4 },
        .{ .code = 'ы', .pos = 274, .width = 5 },
        .{ .code = 'ь', .pos = 279 },
        .{ .code = 'э', .pos = 282, .width = 4 },
        .{ .code = 'ю', .pos = 286, .width = 5 },
        .{ .code = 'я', .pos = 291 },
    };

    pub const Char = struct {
        code: u16,
        pos: i32 = 0,
        width: i32 = 3,
    };
};

pub const Text = struct {
    pos: Point,
    size: Point,
    alignment: Alignment,
    color: Color,
    mesh: gl.Mesh,

    pub fn init(state: State, pos: Point, alignment: Alignment, color: Color, data: []const u16) !Text {
        var advance: i32 = 0;
        if (data.len > 512) return error.TextSizeOverflow;
        var i: usize = 0;
        for (data) |c| {
            if (c == ' ') {
                advance += 3;
                continue;
            }

            const char_pos = state.render.text.positions[c];
            const char_width = state.render.text.widths[c];
            const tex_width = state.render.text.texture.size[0];

            vertices[i * 24 + (4 * 0) + 0] = @as(f32, @floatFromInt(advance)); // X
            vertices[i * 24 + (4 * 0) + 1] = 0.0; // Y
            vertices[i * 24 + (4 * 0) + 2] = @as(f32, @floatFromInt(char_pos)) / @as(f32, @floatFromInt(tex_width)); // U
            vertices[i * 24 + (4 * 0) + 3] = 0.0; // V

            vertices[i * 24 + (4 * 1) + 0] = @as(f32, @floatFromInt(advance)); // X
            vertices[i * 24 + (4 * 1) + 1] = -8.0; // Y
            vertices[i * 24 + (4 * 1) + 2] = @as(f32, @floatFromInt(char_pos)) / @as(f32, @floatFromInt(tex_width)); // U
            vertices[i * 24 + (4 * 1) + 3] = 1.0; // V

            vertices[i * 24 + (4 * 2) + 0] = @as(f32, @floatFromInt(advance)) + @as(f32, @floatFromInt(char_width)); // X
            vertices[i * 24 + (4 * 2) + 1] = -8.0; // Y
            vertices[i * 24 + (4 * 2) + 2] = (@as(f32, @floatFromInt(char_pos)) + @as(f32, @floatFromInt(char_width))) / @as(f32, @floatFromInt(tex_width)); // U
            vertices[i * 24 + (4 * 2) + 3] = 1.0; // V

            vertices[i * 24 + (4 * 3) + 0] = @as(f32, @floatFromInt(advance)) + @as(f32, @floatFromInt(char_width)); // X
            vertices[i * 24 + (4 * 3) + 1] = -8.0; // Y
            vertices[i * 24 + (4 * 3) + 2] = (@as(f32, @floatFromInt(char_pos)) + @as(f32, @floatFromInt(char_width))) / @as(f32, @floatFromInt(tex_width)); // U
            vertices[i * 24 + (4 * 3) + 3] = 1.0; // V

            vertices[i * 24 + (4 * 4) + 0] = @as(f32, @floatFromInt(advance)) + @as(f32, @floatFromInt(char_width)); // X
            vertices[i * 24 + (4 * 4) + 1] = 0.0; // Y
            vertices[i * 24 + (4 * 4) + 2] = (@as(f32, @floatFromInt(char_pos)) + @as(f32, @floatFromInt(char_width))) / @as(f32, @floatFromInt(tex_width)); // U
            vertices[i * 24 + (4 * 4) + 3] = 0.0; // V

            vertices[i * 24 + (4 * 5) + 0] = @as(f32, @floatFromInt(advance)); // X
            vertices[i * 24 + (4 * 5) + 1] = 0.0; // Y
            vertices[i * 24 + (4 * 5) + 2] = @as(f32, @floatFromInt(char_pos)) / @as(f32, @floatFromInt(tex_width)); // U
            vertices[i * 24 + (4 * 5) + 3] = 0.0; // V

            advance += char_width + 1;
            i += 1;
        }

        return Text{
            .pos = pos,
            .size = .{ advance - 1, 8 },
            .alignment = alignment,
            .color = color,
            .mesh = try gl.Mesh.init(vertices[0..(i * 24)], &.{ 2, 2 }, .{ .usage = .static }),
        };
    }

    pub fn deinit(self: Text) void {
        self.mesh.deinit();
    }

    var vertices: [9216]f32 = [1]f32{0.0} ** 9216;
};

pub const Button = struct {
    rect: Rect,
    alignment: Alignment,
    state: enum(u8) { empty, focus, press },
    text: Text,

    pub fn init(state: State, rect: Rect, alignment: Alignment, text: []const u16) !Button {
        return Button{
            .rect = rect,
            .alignment = alignment,
            .state = .empty,
            .text = try Text.init(state, .{ 0, 0 }, alignment, .{ 1.0, 1.0, 1.0, 1.0 }, text),
        };
    }

    pub fn deinit(self: Button) void {
        self.text.deinit();
    }
};

pub const Control = union(enum) {
    text: Text,
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
        text: struct {
            positions: [2048]i32,
            widths: [2048]i32,
            program: gl.Program,
            texture: gl.Texture,
        },
        button: struct {
            program: gl.Program,
            textures: [3]gl.Texture,
        },
    },

    pub fn init(allocator: std.mem.Allocator, vpsize: Point) !State {
        var widths: [2048]i32 = [1]i32{3} ** 2048;
        var positions: [2048]i32 = [1]i32{0} ** 2048;

        for (Font.chars) |char| {
            positions[char.code] = char.pos;
            widths[char.code] = char.width;
        }

        const text_vertex = try gl.Shader.initFormFile(
            allocator,
            "data/shader/gui/text/vertex.glsl",
            gl.Shader.Type.vertex,
        );
        defer text_vertex.deinit();

        const text_fragment = try gl.Shader.initFormFile(
            allocator,
            "data/shader/gui/text/fragment.glsl",
            gl.Shader.Type.fragment,
        );
        defer text_fragment.deinit();

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
            .scale = 3,
            .render = .{
                .rect = .{
                    .mesh = try gl.Mesh.init(
                        &.{ 0.0, 0.0, 0.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, 0.0, 0.0, 0.0 },
                        &.{2},
                        .{},
                    ),
                },
                .text = .{
                    .program = try gl.Program.init(
                        allocator,
                        &.{ text_vertex, text_fragment },
                        &.{ "matrix", "color" },
                    ),
                    .texture = try gl.Texture.init(Font.file),
                    .positions = positions,
                    .widths = widths,
                },
                .button = .{
                    .program = try gl.Program.init(
                        allocator,
                        &.{ button_vertex, button_fragment },
                        &.{ "matrix", "vpsize", "scale", "rect", "texsize" },
                    ),
                    .textures = .{
                        try gl.Texture.init("data/gui/button/empty.png"),
                        try gl.Texture.init("data/gui/button/focus.png"),
                        try gl.Texture.init("data/gui/button/press.png"),
                    },
                },
            },
        };
        std.log.debug("gui init state = {}", .{state});
        return state;
    }

    pub fn deinit(self: State) void {
        std.log.debug("gui deinit state = {}", .{self});
        for (self.render.button.textures) |texture| {
            texture.deinit();
        }
        self.render.button.program.deinit();
        self.render.text.texture.deinit();
        self.render.text.program.deinit();
        self.render.rect.mesh.deinit();
        for (self.controls.items) |control| {
            switch (control) {
                .text => control.text.deinit(),
                .button => control.button.deinit(),
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
                .text => |text| drawText(state, text),
                .button => |button| drawButton(state, button),
            }
        }
    }

    pub fn drawText(state: State, text: Text) void {
        const pos = text.alignment.transform(text.pos * Point{ state.scale, state.scale }, state.vpsize);
        const matrix = trasformMatrix(pos, .{ state.scale, state.scale }, state.vpsize);
        state.render.text.program.use();
        state.render.text.program.setUniform(0, matrix);
        state.render.text.program.setUniform(1, text.color);
        state.render.text.texture.use();
        text.mesh.draw();
    }

    pub fn drawButton(state: State, button: Button) void {
        const pos = button.alignment.transform(button.rect.scale(state.scale), state.vpsize).min;
        const size = button.rect.scale(state.scale).size();
        const matrix: Mat = trasformMatrix(pos, size, state.vpsize);
        state.render.button.program.use();
        state.render.button.program.setUniform(0, matrix);
        state.render.button.program.setUniform(1, state.vpsize);
        state.render.button.program.setUniform(2, state.scale);
        state.render.button.program.setUniform(3, button.alignment.transform(button.rect.scale(state.scale), state.vpsize).vector());
        state.render.button.textures[@intFromEnum(button.state)].use();
        state.render.button.program.setUniform(4, state.render.button.textures[@intFromEnum(button.state)].size);
        state.render.rect.mesh.draw();

        var text: Text = button.text;
        text.pos = button.rect.min + @divTrunc(button.rect.size() - button.text.size, Point{ 2, 2 });

        drawText(state, text);
    }

    pub inline fn trasformMatrix(pos: Point, size: Point, vpsize: Point) Mat {
        var matrix = linmath.identity(Mat);
        matrix[0][0] = @as(f32, @floatFromInt(size[0])) / @as(f32, @floatFromInt(vpsize[0])) * 2.0;
        matrix[0][3] = @as(f32, @floatFromInt(pos[0])) / @as(f32, @floatFromInt(vpsize[0])) * 2.0 - 1.0;
        matrix[1][1] = @as(f32, @floatFromInt(size[1])) / @as(f32, @floatFromInt(vpsize[1])) * 2.0;
        matrix[1][3] = @as(f32, @floatFromInt(pos[1])) / @as(f32, @floatFromInt(vpsize[1])) * -2.0 + 1.0;
        return matrix;
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
                .text => {},
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
