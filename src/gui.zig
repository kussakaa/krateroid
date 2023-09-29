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
        pos: Point = .{ 0, 0 },
        data: []const u16 = &.{},
    };

    pub const Button = struct {
        rect: Rect,
        alignment: Alignment = .{},
        state: enum { empty, focus, press } = .empty,
        label: Text = .{},
    };

    label: Text,
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
            .scale = 4,
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
                    .texture = try gl.Texture.init("data/gui/font.png"),
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
                },
                .label => {},
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

                        if (button.state == .focus and input_state.mouse.buttons[@intFromEnum(input.Mouse.Button.left)]) {
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
            .mouse_button_down => |mouse_button_code| if (mouse_button_code == .left) {
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
            .mouse_button_up => |mouse_button_code| if (mouse_button_code == .left) {
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
