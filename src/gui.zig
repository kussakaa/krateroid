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
