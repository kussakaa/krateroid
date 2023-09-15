const std = @import("std");
const input = @import("input.zig");
const gl = @import("gl.zig");

pub const Color = @Vector(4, f32);
pub const Point = @Vector(2, i32);

pub const Rect = struct {
    min: Point,
    max: Point,

    pub fn isAroundPoint(self: Rect, point: Point) bool {
        if (self.min[0] < point[0] and self.max[2] > point[0] and self.min[1] < point[1] and self.max[3] > point[1]) {
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
    };

    button: struct {
        rect: Rect,
        alignment: Alignment = .{},
        state: enum { empty, focus, press } = .empty,
    },
};

pub const Controls = std.ArrayList(Control);
pub const ControlId = usize;

pub const State = struct {
    controls: std.ArrayList(Control),
    vpsize: Point = .{ 1200, 900 },
    scale: i32 = 1,
    render: struct {
        rect: struct { mesh: gl.Mesh },
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
        const rect_mesh_vertices = [_]f32{
            0.0, 0.0, 0.0, 1.0,
            1.0, 0.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 0.0,
            1.0, 1.0, 1.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        };
        const rect_mesh = gl.Mesh.init(rect_mesh_vertices[0..], &.{ 2, 2 });

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

        var button_program = try gl.Program.init(
            allocator,
            &.{ button_vertex, button_fragment },
        );

        try button_program.addUniform("vpsize");
        try button_program.addUniform("rect");
        try button_program.addUniform("texsize");

        return State{
            .controls = Controls.init(allocator),
            .vpsize = vpsize,
            .render = .{
                .rect = .{ .mesh = rect_mesh },
                .button = .{
                    .program = button_program,
                    .texture = .{
                        .empty = try gl.Texture.init("data/gui/button/empty.png"),
                        .focus = try gl.Texture.init("data/gui/button/focus.png"),
                        .press = try gl.Texture.init("data/gui/button/press.png"),
                    },
                },
            },
        };
    }

    pub fn deinit(self: State) void {
        self.controls.deinit();
        self.render.rect.mesh.deinit();
        self.render.button.program.deinit();
        self.render.button.texture.empty.deinit();
        self.render.button.texture.focus.deinit();
        self.render.button.texture.press.deinit();
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
                Control.button => |button| {
                    state.render.button.program.use();
                    switch (button.state) {
                        .empty => {
                            state.render.button.texture.empty.use();
                            state.render.button.program.setUniform(2, state.render.button.texture.empty.size);
                        },
                        .focus => {
                            state.render.button.texture.focus.use();
                            state.render.button.program.setUniform(2, state.render.button.texture.focus.size);
                        },
                        .press => {
                            state.render.button.texture.press.use();
                            state.render.button.program.setUniform(2, state.render.button.texture.press.size);
                        },
                    }
                    state.render.button.program.setUniform(0, state.vpsize);
                    state.render.button.program.setUniform(1, @Vector(4, i32){ button.rect.min[0], button.rect.min[1], button.rect.max[0], button.rect.max[1] });
                    state.render.rect.mesh.draw();
                },
                //else => {},
            }
        }
    }
};
