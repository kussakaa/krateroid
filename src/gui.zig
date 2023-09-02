const std = @import("std");
const input = @import("input.zig");

const Mesh = @import("mesh.zig").Mesh;
const glsl = @import("glsl.zig");
const shader_sources = @import("shader_sources.zig");

pub const Color = @Vector(4, f32);
pub const Point = @Vector(2, i32);
pub const Rect = @Vector(4, i32);

pub fn isRectAroundPoint(rect: Rect, point: Point) bool {
    if (rect[0] < point[0] and
        rect[2] > point[0] and
        rect[1] < point[1] and
        rect[3] > point[1])
    {
        return true;
    } else {
        return false;
    }
}

pub const Component = union(enum) {
    panel_color: struct {
        rect: Rect,
        color: Color = .{ 0.0, 0.0, 0.0, 1.0 },
    },
    panel_border: struct {
        rect: Rect,
        color: Color = .{ 0.0, 0.0, 0.0, 1.0 },
        width: i32 = 3,
    },
    panel_input: struct {
        rect: Rect,
        state: PanelInputState = .empty,
    },
    panel_input_color: struct {
        rect: Rect,
        state: PanelInputState = .empty,
        color: [3]Color = .{
            .{ 0.2, 0.2, 0.2, 1.0 },
            .{ 0.3, 0.3, 0.3, 1.0 },
            .{ 0.5, 0.5, 0.5, 1.0 },
        },
    },
    text: struct {
        text: []const u16,
        color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
    },
};

const PanelInputState = enum(usize) {
    empty,
    focus,
    press,
};

pub const ComponentId = usize;
pub const ControlId = usize;
pub const Control = std.ArrayList(Component);
pub const Controls = std.ArrayList(Control);

pub const Properties = struct {
    vpsize: Point = .{ 1200, 900 },
};

pub const RenderSystem = struct {
    vpsize: Point,
    rect_mesh: Mesh,
    panel_color_program: glsl.Program,
    panel_border_program: glsl.Program,

    pub fn init(allocator: std.mem.Allocator, properties: Properties) !RenderSystem {
        const rect_mesh_vertices = [_]f32{
            0.0, 0.0, 0.0, 1.0,
            1.0, 0.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 0.0,
            1.0, 1.0, 1.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        };
        const rect_mesh = Mesh.init(rect_mesh_vertices[0..], &.{ 2, 2 });

        const panel_color_vertex = try glsl.Shader.initFormFile(
            allocator,
            "data/shader/gui/panel/color/vertex.glsl",
            glsl.Shader.Type.vertex,
        );
        defer panel_color_vertex.deinit();

        const panel_color_fragment = try glsl.Shader.initFormFile(
            allocator,
            "data/shader/gui/panel/color/fragment.glsl",
            glsl.Shader.Type.fragment,
        );
        defer panel_color_fragment.deinit();

        var panel_color_program = try glsl.Program.init(
            allocator,
            &.{ panel_color_vertex, panel_color_fragment },
        );

        try panel_color_program.addUniform("vpsize");
        try panel_color_program.addUniform("rect");
        try panel_color_program.addUniform("color");

        const panel_border_vertex = try glsl.Shader.initFormFile(
            allocator,
            "data/shader/gui/panel/border/vertex.glsl",
            glsl.Shader.Type.vertex,
        );
        defer panel_border_vertex.deinit();

        const panel_border_fragment = try glsl.Shader.initFormFile(
            allocator,
            "data/shader/gui/panel/border/fragment.glsl",
            glsl.Shader.Type.fragment,
        );
        defer panel_border_fragment.deinit();

        var panel_border_program = try glsl.Program.init(
            allocator,
            &.{ panel_border_vertex, panel_border_fragment },
        );

        try panel_border_program.addUniform("vpsize");
        try panel_border_program.addUniform("rect");
        try panel_border_program.addUniform("color");
        try panel_border_program.addUniform("width");

        return RenderSystem{
            .vpsize = properties.vpsize,
            .rect_mesh = rect_mesh,
            .panel_color_program = panel_color_program,
            .panel_border_program = panel_border_program,
        };
    }

    pub fn deinit(self: RenderSystem) void {
        self.rect_mesh.deinit();
        self.panel_color_program.deinit();
        self.panel_border_program.deinit();
    }

    pub fn draw(self: RenderSystem, controls: Controls) void {
        for (controls.items) |control| {
            for (control.items) |component| {
                switch (component) {
                    Component.panel_color => |panel| {
                        self.panel_color_program.use();
                        self.panel_color_program.setUniform(0, self.vpsize);
                        self.panel_color_program.setUniform(1, panel.rect);
                        self.panel_color_program.setUniform(2, panel.color);
                        self.rect_mesh.draw();
                    },
                    Component.panel_border => |panel| {
                        self.panel_border_program.use();
                        self.panel_border_program.setUniform(0, self.vpsize);
                        self.panel_border_program.setUniform(1, panel.rect);
                        self.panel_border_program.setUniform(2, panel.color);
                        self.panel_border_program.setUniform(3, panel.width);
                        self.rect_mesh.draw();
                    },
                    Component.panel_input_color => |panel| {
                        self.panel_color_program.use();
                        self.panel_color_program.setUniform(0, self.vpsize);
                        self.panel_color_program.setUniform(1, panel.rect);
                        self.panel_color_program.setUniform(2, panel.color[@intFromEnum(panel.state)]);
                        self.rect_mesh.draw();
                    },
                    Component.text => {},
                    else => {},
                }
            }
        }
    }
};

pub const InputSystem = struct {
    pub fn process(controls: Controls, input_event: input.Event, properties: Properties) ?Event {
        for (controls.items, 0..) |control, control_id| {
            for (control.items, 0..) |component, component_id| {
                switch (component) {
                    .panel_input => |panel| {
                        switch (input_event) {
                            .mouse_motion => |motion| {
                                const point = Point{ motion[0], properties.vpsize[1] - motion[1] };
                                if (panel.state == .empty and isRectAroundPoint(panel.rect, point)) {
                                    return Event{ .panel_focussed = .{ .control = control_id, .component = component_id } };
                                } else if (panel.state != .empty and !isRectAroundPoint(panel.rect, point)) {
                                    return Event{ .panel_unfocussed = .{ .control = control_id, .component = component_id } };
                                }
                            },
                            .mouse_button_down => |button| {
                                if (panel.state == .focus and button == .left) {
                                    return Event{ .panel_pressed = .{ .control = control_id, .component = component_id } };
                                }
                            },
                            .mouse_button_up => |button| {
                                if (panel.state == .press and button == .left) {
                                    return Event{ .panel_unpressed = .{ .control = control_id, .component = component_id } };
                                }
                            },
                            else => {},
                        }
                    },
                    .panel_input_color => |panel| {
                        switch (input_event) {
                            .mouse_motion => |motion| {
                                const point = Point{ motion[0], properties.vpsize[1] - motion[1] };
                                if (panel.state == .empty and isRectAroundPoint(panel.rect, point)) {
                                    return Event{ .panel_focussed = .{ .control = control_id, .component = component_id } };
                                } else if (panel.state != .empty and !isRectAroundPoint(panel.rect, point)) {
                                    return Event{ .panel_unfocussed = .{ .control = control_id, .component = component_id } };
                                }
                            },
                            .mouse_button_down => |button| {
                                if (panel.state == .focus and button == .left) {
                                    return Event{ .panel_pressed = .{ .control = control_id, .component = component_id } };
                                }
                            },
                            .mouse_button_up => |button| {
                                if (panel.state == .press and button == .left) {
                                    return Event{ .panel_unpressed = .{ .control = control_id, .component = component_id } };
                                }
                            },
                            else => {},
                        }
                    },
                    else => {},
                }
            }
        }
        return null;
    }
};

pub const Event = union(enum) {
    panel_focussed: struct { control: ControlId, component: ComponentId },
    panel_unfocussed: struct { control: ControlId, component: ComponentId },
    panel_pressed: struct { control: ControlId, component: ComponentId },
    panel_unpressed: struct { control: ControlId, component: ComponentId },
};

pub const EventSystem = struct {
    pub fn process(controls: *Controls, event: Event) void {
        switch (event) {
            .panel_focussed => |id| {
                const state: *PanelInputState = switch (controls.*.items[id.control].items[id.component]) {
                    .panel_input => |*panel| &panel.state,
                    .panel_input_color => |*panel| &panel.state,
                    else => @panic("Invalid component type"),
                };
                if (state.* == .empty) state.* = .focus;
            },
            .panel_unfocussed => |id| {
                const state: *PanelInputState = switch (controls.*.items[id.control].items[id.component]) {
                    .panel_input => |*panel| &panel.state,
                    .panel_input_color => |*panel| &panel.state,
                    else => @panic("Invalid component type"),
                };
                state.* = .empty;
            },
            .panel_pressed => |id| {
                const state: *PanelInputState = switch (controls.*.items[id.control].items[id.component]) {
                    .panel_input => |*panel| &panel.state,
                    .panel_input_color => |*panel| &panel.state,
                    else => @panic("Invalid component type"),
                };
                if (state.* == .focus) state.* = .press;
            },
            .panel_unpressed => |id| {
                const state: *PanelInputState = switch (controls.*.items[id.control].items[id.component]) {
                    .panel_input => |*panel| &panel.state,
                    .panel_input_color => |*panel| &panel.state,
                    else => @panic("Invalid component type"),
                };
                if (state.* == .press) state.* = .focus;
            },
        }
    }
};
