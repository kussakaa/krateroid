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
        .{ .code = '1', .pos = 36, .width = 1 },
        .{ .code = '2', .pos = 37 },
        .{ .code = '3', .pos = 40 },
        .{ .code = '4', .pos = 43 },
        .{ .code = '5', .pos = 46 },
        .{ .code = '6', .pos = 49 },
        .{ .code = '7', .pos = 52 },
        .{ .code = '8', .pos = 55 },
        .{ .code = '9', .pos = 58 },
        .{ .code = ':', .pos = 61, .width = 1 },
        .{ .code = ';', .pos = 62, .width = 1 },
        .{ .code = '<', .pos = 63 },
        .{ .code = '=', .pos = 66 },
        .{ .code = '>', .pos = 69 },
        .{ .code = '?', .pos = 72 },
        .{ .code = '@', .pos = 75, .width = 5 },
        .{ .code = 'a', .pos = 80 },
        .{ .code = 'b', .pos = 83 },
        .{ .code = 'c', .pos = 86 },
        .{ .code = 'd', .pos = 89 },
        .{ .code = 'e', .pos = 92 },
        .{ .code = 'f', .pos = 95 },
        .{ .code = 'g', .pos = 98 },
        .{ .code = 'h', .pos = 101 },
        .{ .code = 'i', .pos = 104, .width = 1 },
        .{ .code = 'j', .pos = 105 },
        .{ .code = 'k', .pos = 108 },
        .{ .code = 'l', .pos = 111 },
        .{ .code = 'm', .pos = 114 },
        .{ .code = 'n', .pos = 119 },
        .{ .code = 'o', .pos = 123 },
        .{ .code = 'p', .pos = 126 },
        .{ .code = 'q', .pos = 129 },
        .{ .code = 'r', .pos = 132 },
        .{ .code = 's', .pos = 135 },
        .{ .code = 't', .pos = 138 },
        .{ .code = 'u', .pos = 141 },
        .{ .code = 'v', .pos = 144 },
        .{ .code = 'w', .pos = 147 },
        .{ .code = 'x', .pos = 152 },
        .{ .code = 'y', .pos = 155 },
        .{ .code = 'z', .pos = 158 },
        .{ .code = '[', .pos = 161, .width = 2 },
        .{ .code = '\\', .pos = 163, .width = 3 },
        .{ .code = ']', .pos = 166, .width = 2 },
        .{ .code = '^', .pos = 168 },
        .{ .code = '_', .pos = 171 },
        .{ .code = 'а', .pos = 174 },
        .{ .code = 'б', .pos = 177 },
        .{ .code = 'в', .pos = 180 },
        .{ .code = 'г', .pos = 183 },
        .{ .code = 'д', .pos = 186, .width = 5 },
        .{ .code = 'е', .pos = 191 },
        .{ .code = 'ё', .pos = 194 },
        .{ .code = 'ж', .pos = 197, .width = 5 },
        .{ .code = 'з', .pos = 202 },
        .{ .code = 'и', .pos = 205, .width = 4 },
        .{ .code = 'й', .pos = 209, .width = 4 },
        .{ .code = 'к', .pos = 213 },
        .{ .code = 'л', .pos = 216 },
        .{ .code = 'м', .pos = 219, .width = 5 },
        .{ .code = 'н', .pos = 224 },
        .{ .code = 'о', .pos = 227 },
        .{ .code = 'п', .pos = 230 },
        .{ .code = 'р', .pos = 233 },
        .{ .code = 'с', .pos = 236 },
        .{ .code = 'т', .pos = 239 },
        .{ .code = 'у', .pos = 242 },
        .{ .code = 'ф', .pos = 245, .width = 5 },
        .{ .code = 'х', .pos = 250 },
        .{ .code = 'ц', .pos = 253 },
        .{ .code = 'ч', .pos = 256 },
        .{ .code = 'ш', .pos = 259, .width = 5 },
        .{ .code = 'щ', .pos = 264, .width = 5 },
        .{ .code = 'ъ', .pos = 269, .width = 4 },
        .{ .code = 'ы', .pos = 273, .width = 5 },
        .{ .code = 'ь', .pos = 278 },
        .{ .code = 'э', .pos = 281, .width = 4 },
        .{ .code = 'ю', .pos = 285, .width = 5 },
        .{ .code = 'я', .pos = 290 },
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

            const widthf = @as(f32, @floatFromInt(width));
            const cposf = @as(f32, @floatFromInt(state.render.text.positions[c]));
            const cwidthf = @as(f32, @floatFromInt(state.render.text.widths[c]));
            const texwidthf = @as(f32, @floatFromInt(state.render.text.texture.size[0]));
            const rect = Vec{ widthf, 0.0, widthf + cwidthf, -8.0 };
            const uvrect = Vec{ cposf / texwidthf, 0.0, (cposf + cwidthf) / texwidthf, 1.0 };

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
