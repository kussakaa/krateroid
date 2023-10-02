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

    pub const Text = struct {
        pos: Point,
        size: Point,
        mesh: gl.Mesh,

        pub fn init(state: State, data: []const u16) !Text {
            var advance: i32 = 0;
            if (data.len > 512) return error.TextSizeOverflow;
            var i: usize = 0;
            for (data) |c| {
                if (c == ' ') {
                    advance += 3;
                    continue;
                }

                const pos = state.render.text.positions[c];
                const width = state.render.text.widths[c];
                const tex_width = state.render.text.texture.size[0];

                vertices[i * 24 + (4 * 0) + 0] = @as(f32, @floatFromInt(advance)); // X
                vertices[i * 24 + (4 * 0) + 1] = 0.0; // Y
                vertices[i * 24 + (4 * 0) + 2] = @as(f32, @floatFromInt(pos)) / @as(f32, @floatFromInt(tex_width)); // U
                vertices[i * 24 + (4 * 0) + 3] = 1.0; // V

                vertices[i * 24 + (4 * 1) + 0] = @as(f32, @floatFromInt(advance)) + @as(f32, @floatFromInt(width)); // X
                vertices[i * 24 + (4 * 1) + 1] = 0.0; // Y
                vertices[i * 24 + (4 * 1) + 2] = (@as(f32, @floatFromInt(pos)) + @as(f32, @floatFromInt(width))) / @as(f32, @floatFromInt(tex_width)); // U
                vertices[i * 24 + (4 * 1) + 3] = 1.0; // V

                vertices[i * 24 + (4 * 2) + 0] = @as(f32, @floatFromInt(advance)) + @as(f32, @floatFromInt(width)); // X
                vertices[i * 24 + (4 * 2) + 1] = 8.0; // Y
                vertices[i * 24 + (4 * 2) + 2] = (@as(f32, @floatFromInt(pos)) + @as(f32, @floatFromInt(width))) / @as(f32, @floatFromInt(tex_width)); // U
                vertices[i * 24 + (4 * 2) + 3] = 0.0; // V

                vertices[i * 24 + (4 * 3) + 0] = @as(f32, @floatFromInt(advance)) + @as(f32, @floatFromInt(width)); // X
                vertices[i * 24 + (4 * 3) + 1] = 8.0; // Y
                vertices[i * 24 + (4 * 3) + 2] = (@as(f32, @floatFromInt(pos)) + @as(f32, @floatFromInt(width))) / @as(f32, @floatFromInt(tex_width)); // U
                vertices[i * 24 + (4 * 3) + 3] = 0.0; // V

                vertices[i * 24 + (4 * 4) + 0] = @as(f32, @floatFromInt(advance)); // X
                vertices[i * 24 + (4 * 4) + 1] = 8.0; // Y
                vertices[i * 24 + (4 * 4) + 2] = @as(f32, @floatFromInt(pos)) / @as(f32, @floatFromInt(tex_width)); // U
                vertices[i * 24 + (4 * 4) + 3] = 0.0; // V

                vertices[i * 24 + (4 * 5) + 0] = @as(f32, @floatFromInt(advance)); // X
                vertices[i * 24 + (4 * 5) + 1] = 0.0; // Y
                vertices[i * 24 + (4 * 5) + 2] = @as(f32, @floatFromInt(pos)) / @as(f32, @floatFromInt(tex_width)); // U
                vertices[i * 24 + (4 * 5) + 3] = 1.0; // V

                advance += width + 1;
                i += 1;
            }

            return Text{
                .pos = .{ 0, 0 },
                .size = .{ advance - 1, 8 },
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
        alignment: Alignment = .{},
        state: enum { empty, focus, press } = .empty,
        text: Text,
    };

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
            texture: struct {
                empty: gl.Texture,
                focus: gl.Texture,
                press: gl.Texture,
            },
        },
    },

    pub fn init(allocator: std.mem.Allocator, vpsize: Point) !State {
        var widths: [2048]i32 = [1]i32{3} ** 2048;
        widths['!'] = 1;
        widths['#'] = 5;
        widths['\''] = 1;
        widths['('] = 2;
        widths[')'] = 2;
        widths[','] = 1;
        widths['-'] = 2;
        widths['.'] = 1;
        widths['1'] = 2;
        widths[':'] = 1;
        widths[';'] = 1;
        widths['@'] = 4;
        widths['i'] = 1;
        widths['m'] = 5;
        widths['n'] = 4;
        widths['['] = 2;
        widths[']'] = 2;
        widths['ж'] = 5;
        widths['и'] = 4;
        widths['й'] = 4;
        widths['м'] = 5;
        widths['ф'] = 4;
        widths['ц'] = 4;
        widths['ш'] = 5;
        widths['щ'] = 5;
        widths['ъ'] = 4;
        widths['ы'] = 5;
        widths['э'] = 4;
        widths['ю'] = 5;

        var positions: [2048]i32 = [1]i32{0} ** 2048;
        positions['!'] = 3;
        positions['"'] = 4;
        positions['#'] = 7;
        positions['$'] = 12;
        positions['\''] = 15;
        positions['('] = 16;
        positions[')'] = 18;
        positions['*'] = 20;
        positions['+'] = 23;
        positions[','] = 26;
        positions['-'] = 27;
        positions['.'] = 29;
        positions['/'] = 30;
        positions['0'] = 33;
        positions['1'] = 36;
        positions['2'] = 38;
        positions['3'] = 41;
        positions['4'] = 44;
        positions['5'] = 47;
        positions['6'] = 50;
        positions['7'] = 53;
        positions['8'] = 56;
        positions['9'] = 59;
        positions[':'] = 62;
        positions[';'] = 63;
        positions['<'] = 64;
        positions['='] = 67;
        positions['>'] = 70;
        positions['?'] = 73;
        positions['@'] = 76;
        positions['a'] = 81;
        positions['b'] = 84;
        positions['c'] = 87;
        positions['d'] = 90;
        positions['e'] = 93;
        positions['f'] = 96;
        positions['g'] = 99;
        positions['h'] = 102;
        positions['i'] = 105;
        positions['j'] = 106;
        positions['k'] = 109;
        positions['l'] = 112;
        positions['m'] = 115;
        positions['n'] = 120;
        positions['o'] = 124;
        positions['p'] = 127;
        positions['q'] = 130;
        positions['r'] = 133;
        positions['s'] = 136;
        positions['t'] = 139;
        positions['u'] = 142;
        positions['v'] = 145;
        positions['w'] = 148;
        positions['x'] = 153;
        positions['y'] = 156;
        positions['z'] = 159;
        positions['['] = 162;
        positions['\\'] = 164;
        positions[']'] = 167;
        positions['^'] = 169;
        positions['_'] = 172;
        positions['а'] = 81;
        positions['б'] = 175;
        positions['в'] = 84;
        positions['г'] = 178;
        positions['д'] = 181;
        positions['е'] = 93;
        positions['ё'] = 186;
        positions['ж'] = 189;
        positions['з'] = 194;
        positions['и'] = 197;
        positions['й'] = 201;
        positions['к'] = 109;
        positions['л'] = 205;
        positions['м'] = 115;
        positions['н'] = 102;
        positions['о'] = 124;
        positions['п'] = 208;
        positions['р'] = 127;
        positions['с'] = 87;
        positions['т'] = 139;
        positions['у'] = 156;
        positions['ф'] = 211;
        positions['х'] = 153;
        positions['ц'] = 216;
        positions['ч'] = 220;
        positions['ш'] = 223;
        positions['щ'] = 228;
        positions['ъ'] = 233;
        positions['ы'] = 237;
        positions['ь'] = 242;
        positions['э'] = 245;
        positions['ю'] = 249;
        positions['я'] = 25;

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
                        &.{ 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0 },
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
                    .texture = try gl.Texture.init("data/gui/text/font.png"),
                    .positions = positions,
                    .widths = widths,
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
        self.render.text.texture.deinit();
        self.render.text.program.deinit();
        self.render.rect.mesh.deinit();
        for (self.controls.items) |control| {
            switch (control) {
                .text => control.text.deinit(),
                .button => control.button.text.deinit(),
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
                .text => {},
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

                    const text_pos = pos + (@divTrunc(button.rect.size() - button.text.size, Point{ 2, 2 })) * Point{ state.scale, state.scale };
                    const matrix_text = linmath.Mat{
                        .{
                            @as(f32, @floatFromInt(state.scale)) / @as(f32, @floatFromInt(state.vpsize[0])) * 2.0,
                            0.0,
                            0.0,
                            @as(f32, @floatFromInt(text_pos[0])) / @as(f32, @floatFromInt(state.vpsize[0])) * 2.0 - 1.0,
                        },
                        .{
                            0.0,
                            @as(f32, @floatFromInt(state.scale)) / @as(f32, @floatFromInt(state.vpsize[1])) * 2.0,
                            0.0,
                            @as(f32, @floatFromInt(text_pos[1])) / @as(f32, @floatFromInt(state.vpsize[1])) * 2.0 - 1.0,
                        },
                        .{ 0.0, 0.0, 1.0, 0.0 },
                        .{ 0.0, 0.0, 0.0, 1.0 },
                    };
                    state.render.text.program.use();
                    state.render.text.program.setUniform(0, matrix_text);
                    state.render.text.program.setUniform(1, Color{ 1.0, 1.0, 1.0, 1.0 });
                    state.render.text.texture.use();
                    button.text.mesh.draw();
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
