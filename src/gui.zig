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
    const Horizontal = enum { left, center, right };
    const Vertical = enum { bottom, center, top };

    horizontal: Horizontal = .left,
    vertical: Vertical = .top,

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

pub const Control = union(enum) {
    text: Text,
    button: Button,
};

pub const Panel = struct {
    rect: Rect,
    controls: std.ArrayList(Control),
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
        .{ .code = '1', .pos = 36, .width = 2 },
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
    vertices: gl.Mesh.Vertices,
    style: Style,

    pub const Style = struct {
        color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
    };

    pub const InitInfo = struct {
        state: State = undefined,
        data: []const u16,
        pos: Point = .{ 0, 0 },
        alignment: Alignment = .{},
        usage: enum { static, dynamic } = .static,
        style: Style,
    };

    pub fn init(info: InitInfo) !Text {
        const vertices = try initVertices(info.state, info.data);
        return Text{
            .pos = info.pos,
            .size = .{ vertices.width - 1, 8 },
            .alignment = info.alignment,
            .vertices = try gl.Mesh.Vertices.init(.{
                .data = vertices.data,
                .attrs = &.{ 2, 2 },
                .usage = .dynamic,
            }),
            .style = info.style,
        };
    }

    pub fn deinit(self: Text) void {
        self.vertices.deinit();
    }

    pub fn subdata(self: *Text, state: State, data: []const u16) !void {
        const vertices = try initVertices(state, data);
        self.size[0] = vertices.width;
        try self.vertices.subdata(vertices.data);
    }

    pub fn initVertices(state: State, data: []const u16) !struct { data: []const f32, width: i32 } {
        var width: i32 = 0;
        if (data.len > 512) return error.TextSizeOverflow;
        var i: usize = 0;
        for (data) |c| {
            if (c == ' ') {
                width += 3;
                continue;
            }

            const rect = Vec{
                @as(f32, @floatFromInt(width)),
                0.0,
                @as(f32, @floatFromInt(width + state.render.text.widths[c])),
                -8.0,
            };

            const uvrect = Vec{
                @as(f32, @floatFromInt(state.render.text.positions[c])) / @as(f32, @floatFromInt(state.render.text.texture.size[0])),
                0.0,
                @as(f32, @floatFromInt(state.render.text.positions[c] + state.render.text.widths[c])) / @as(f32, @floatFromInt(state.render.text.texture.size[0])),
                1.0,
            };

            vertices_data[i * 24 + (4 * 0) + 0] = rect[0];
            vertices_data[i * 24 + (4 * 0) + 1] = rect[1];
            vertices_data[i * 24 + (4 * 0) + 2] = uvrect[0];
            vertices_data[i * 24 + (4 * 0) + 3] = uvrect[1];

            vertices_data[i * 24 + (4 * 1) + 0] = rect[0];
            vertices_data[i * 24 + (4 * 1) + 1] = rect[3];
            vertices_data[i * 24 + (4 * 1) + 2] = uvrect[0];
            vertices_data[i * 24 + (4 * 1) + 3] = uvrect[3];

            vertices_data[i * 24 + (4 * 2) + 0] = rect[2];
            vertices_data[i * 24 + (4 * 2) + 1] = rect[3];
            vertices_data[i * 24 + (4 * 2) + 2] = uvrect[2];
            vertices_data[i * 24 + (4 * 2) + 3] = uvrect[3];

            vertices_data[i * 24 + (4 * 3) + 0] = rect[2];
            vertices_data[i * 24 + (4 * 3) + 1] = rect[3];
            vertices_data[i * 24 + (4 * 3) + 2] = uvrect[2];
            vertices_data[i * 24 + (4 * 3) + 3] = uvrect[3];

            vertices_data[i * 24 + (4 * 4) + 0] = rect[2];
            vertices_data[i * 24 + (4 * 4) + 1] = rect[1];
            vertices_data[i * 24 + (4 * 4) + 2] = uvrect[2];
            vertices_data[i * 24 + (4 * 4) + 3] = uvrect[1];

            vertices_data[i * 24 + (4 * 5) + 0] = rect[0];
            vertices_data[i * 24 + (4 * 5) + 1] = rect[1];
            vertices_data[i * 24 + (4 * 5) + 2] = uvrect[0];
            vertices_data[i * 24 + (4 * 5) + 3] = uvrect[1];

            width += state.render.text.widths[c] + 1;
            i += 1;
        }

        return .{
            .data = vertices_data[0..(i * 24)],
            .width = width,
        };
    }

    var vertices_data: [12288]f32 = [1]f32{0.0} ** 12288;
};

pub const Button = struct {
    id: u32 = 0,
    rect: Rect,
    alignment: Alignment,
    state: enum(u8) { empty, focus, press } = .empty,
    text: Text,
    style: Style,

    pub const Style = struct {
        states: [3]struct {
            texture: gl.Texture,
            text: Text.Style,
        },
    };

    const InitInfo = struct {
        state: State = undefined,
        id: u32 = 0,
        rect: Rect,
        alignment: Alignment = .{},
        text: []const u16 = &.{'-'},
        style: Style,
    };

    pub fn init(info: InitInfo) !Button {
        return Button{
            .id = info.id,
            .rect = info.rect,
            .alignment = info.alignment,
            .state = .empty,
            .style = info.style,
            .text = try Text.init(.{
                .state = info.state,
                .data = info.text,
                .alignment = info.alignment,
                .style = info.style.states[0].text,
            }),
        };
    }

    pub fn deinit(self: Button) void {
        self.text.deinit();
    }
};

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
        },
    },

    pub fn init(allocator: std.mem.Allocator, vpsize: Point) !State {
        var widths: [2048]i32 = [1]i32{3} ** 2048;
        var positions: [2048]i32 = [1]i32{0} ** 2048;

        for (Font.chars) |char| {
            positions[char.code] = char.pos;
            widths[char.code] = char.width;
        }

        const state = State{
            .controls = std.ArrayList(Control).init(allocator),
            .vpsize = vpsize,
            .scale = 3,
            .render = .{
                .rect = .{
                    .mesh = .{
                        .vertices = try gl.Mesh.Vertices.init(.{
                            .data = &.{ 0.0, 0.0, 0.0, -1.0, 1.0, -1.0, 1.0, 0.0 },
                            .attrs = &.{2},
                        }),
                        .elements = try gl.Mesh.Elements.init(.{
                            .data = &.{ 0, 1, 2, 2, 3, 0 },
                        }),
                    },
                },

                .text = .{
                    .program = try gl.Program.init(
                        allocator,
                        &.{
                            try gl.Shader.initFormFile(
                                allocator,
                                "data/shader/gui/text/vertex.glsl",
                                gl.Shader.Type.vertex,
                            ),
                            try gl.Shader.initFormFile(
                                allocator,
                                "data/shader/gui/text/fragment.glsl",
                                gl.Shader.Type.fragment,
                            ),
                        },
                        &.{ "matrix", "color" },
                    ),
                    .texture = try gl.Texture.init(Font.file),
                    .positions = positions,
                    .widths = widths,
                },
                .button = .{
                    .program = try gl.Program.init(
                        allocator,
                        &.{
                            try gl.Shader.initFormFile(
                                allocator,
                                "data/shader/gui/button/vertex.glsl",
                                gl.Shader.Type.vertex,
                            ),
                            try gl.Shader.initFormFile(
                                allocator,
                                "data/shader/gui/button/fragment.glsl",
                                gl.Shader.Type.fragment,
                            ),
                        },
                        &.{ "matrix", "vpsize", "scale", "rect", "texsize" },
                    ),
                },
            },
        };
        std.log.debug("init gui state = {}", .{state});
        return state;
    }

    pub fn deinit(self: State) void {
        std.log.debug("deinit gui state = {}", .{self});
        self.render.button.program.deinit();
        self.render.text.texture.deinit();
        self.render.text.program.deinit();
        self.render.rect.mesh.vertices.deinit();
        self.render.rect.mesh.elements.deinit();
        for (self.controls.items) |control| {
            switch (control) {
                .text => control.text.deinit(),
                .button => control.button.deinit(),
            }
        }
        self.controls.deinit();
    }

    pub fn text(self: *State, info: Text.InitInfo) !*Text {
        var text_init_info: Text.InitInfo = info;
        text_init_info.state = self.*;
        const ctext = try Text.init(text_init_info); // инициализация константы текста
        std.log.debug("init gui text = {}", .{ctext});
        try self.controls.append(.{ .text = ctext });
        return &self.controls.items[self.controls.items.len - 1].text;
    }

    pub fn button(self: *State, info: Button.InitInfo) !*Button {
        var button_init_info: Button.InitInfo = info;
        button_init_info.state = self.*;
        button_init_info.id = @as(u32, @intCast(self.controls.items.len));
        const cbutton = try Button.init(button_init_info); // инициализация константы кнопки
        std.log.debug("init gui button = {}", .{cbutton});
        try self.controls.append(.{ .button = cbutton });
        return &self.controls.items[self.controls.items.len - 1].button;
    }
};

pub const RenderSystem = struct {
    pub fn draw(state: State) !void {
        for (state.controls.items) |control| {
            switch (control) {
                .text => |text| try drawText(state, text),
                .button => |button| try drawButton(state, button),
            }
        }
    }

    pub fn drawText(state: State, text: Text) !void {
        const pos = text.alignment.transform(text.pos * Point{ state.scale, state.scale }, state.vpsize);
        const matrix = trasformMatrix(pos, .{ state.scale, state.scale }, state.vpsize);
        state.render.text.program.use();
        state.render.text.program.setUniform(0, matrix);
        state.render.text.program.setUniform(1, text.style.color);
        state.render.text.texture.use();
        try text.vertices.draw();
    }

    pub fn drawButton(state: State, button: Button) !void {
        const pos = button.alignment.transform(button.rect.scale(state.scale), state.vpsize).min;
        const size = button.rect.scale(state.scale).size();
        const matrix: Mat = trasformMatrix(pos, size, state.vpsize);
        state.render.button.program.use();
        state.render.button.program.setUniform(0, matrix);
        state.render.button.program.setUniform(1, state.vpsize);
        state.render.button.program.setUniform(2, state.scale);
        state.render.button.program.setUniform(3, button.alignment.transform(button.rect.scale(state.scale), state.vpsize).vector());
        state.render.button.program.setUniform(4, button.style.states[@intFromEnum(button.state)].texture.size);
        button.style.states[@intFromEnum(button.state)].texture.use();
        try state.render.rect.mesh.draw();

        var text: Text = button.text;
        text.pos = button.rect.min + @divTrunc(button.rect.size() - button.text.size, Point{ 2, 2 });
        text.style = button.style.states[@intFromEnum(button.state)].text;
        try drawText(state, text);
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
    press: u32,
    unpress: u32,
    none,
};

pub const EventSystem = struct {
    pub fn process(state: State, input_state: input.State, event: input.Event) Event {
        switch (event) {
            .mouse_button_down => |mouse_button_code| if (mouse_button_code == 1) {
                for (state.controls.items) |control| {
                    switch (control) {
                        .button => |button| {
                            if (button.alignment.transform(
                                button.rect.scale(state.scale),
                                state.vpsize,
                            ).isAroundPoint(input_state.cursor.pos)) {
                                return .{ .press = button.id };
                            }
                        },
                        else => {},
                    }
                }
            },
            .mouse_button_up => |mouse_button_code| if (mouse_button_code == 1) {
                for (state.controls.items) |control| {
                    switch (control) {
                        .button => |button| {
                            if (button.alignment.transform(
                                button.rect.scale(state.scale),
                                state.vpsize,
                            ).isAroundPoint(input_state.cursor.pos)) {
                                return .{ .unpress = button.id };
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
