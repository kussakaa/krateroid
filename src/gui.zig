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

pub const ComponentTag = enum(usize) {
    rect,
    alignment,
    color,
    border,
    text,
    button,
};

pub const Component = union(ComponentTag) {
    rect: Rect,
    alignment: struct {
        horizontal: enum {
            left,
            center,
            right,
        } = .left,
        vertical: enum {
            bottom,
            center,
            top,
        } = .bottom,
    },
    color: Color,
    border: struct {
        color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
        width: i32 = 3,
    },
    text: struct {
        text: []const u16,
        color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
    },
    button: struct {
        state: enum {
            empty,
            focus,
            press,
        } = .empty,
    },
};

pub const ControlId = usize;
pub const Control = std.ArrayListUnmanaged(Component);
pub const Controls = std.ArrayList(Control);

pub fn getComponent(control: Control, comptime component_tag: ComponentTag) ?Component {
    for (control.items) |component| {
        if (@as(ComponentTag, component) == component_tag) {
            return component;
        }
    }
    return null;
}

pub const State = struct {
    controls: Controls,
    vpsize: Point = .{ 1200, 900 },
    render: struct {
        rect_mesh: Mesh,
        panel_color_program: glsl.Program,
        panel_border_program: glsl.Program,
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

        return State{
            .controls = Controls.init(allocator),
            .vpsize = vpsize,
            .render = .{
                .rect_mesh = rect_mesh,
                .panel_color_program = panel_color_program,
                .panel_border_program = panel_border_program,
            },
        };
    }

    pub fn deinit(self: State) void {
        self.controls.deinit();
        self.render.rect_mesh.deinit();
        self.render.panel_color_program.deinit();
        self.render.panel_border_program.deinit();
    }

    pub fn addControl(self: *State, components: []const Component) !ControlId {
        try self.controls.append(try Control.initCapacity(self.controls.allocator, components.len));
        try self.controls.items[self.controls.items.len - 1].appendSlice(self.controls.allocator, components);
        return self.controls.items.len - 1;
    }
};

pub const RenderSystem = struct {
    pub fn draw(state: State) void {
        for (state.controls.items) |control| {
            var rect: Rect = undefined;
            for (control.items) |component| {
                switch (component) {
                    Component.rect => |_rect| rect = _rect,
                    Component.alignment => |alignment| {
                        switch (alignment.horizontal) {
                            .left => {},
                            .center => {
                                rect[0] += @divTrunc(state.vpsize[0], 2);
                                rect[2] += @divTrunc(state.vpsize[0], 2);
                            },
                            .right => {
                                rect[0] += state.vpsize[0];
                                rect[2] += state.vpsize[0];
                            },
                        }
                        switch (alignment.vertical) {
                            .bottom => {},
                            .center => {
                                rect[1] += @divTrunc(state.vpsize[1], 2);
                                rect[3] += @divTrunc(state.vpsize[1], 2);
                            },
                            .top => {
                                rect[1] += state.vpsize[1];
                                rect[3] += state.vpsize[1];
                            },
                        }
                    },
                    Component.color => |color| {
                        state.render.panel_color_program.use();
                        state.render.panel_color_program.setUniform(0, state.vpsize);
                        state.render.panel_color_program.setUniform(1, rect);
                        state.render.panel_color_program.setUniform(2, color);
                        state.render.rect_mesh.draw();
                    },
                    Component.border => |border| {
                        state.render.panel_border_program.use();
                        state.render.panel_border_program.setUniform(0, state.vpsize);
                        state.render.panel_border_program.setUniform(1, rect);
                        state.render.panel_border_program.setUniform(2, border.color);
                        state.render.panel_border_program.setUniform(3, border.width);
                        state.render.rect_mesh.draw();
                    },
                    Component.text => {},
                    else => {},
                }
            }
        }
    }
};

// pub const InputSystem = struct {
//    pub fn process(controls: Controls, input_event: input.Event) ?Event {
//        for (controls.items, 0..) |control, control_id| {
//            for (control.items, 0..) |component, component_id| {
//                switch (component) {
//                    inline .panel_input, .panel_input_color => |panel| {
//                        switch (input_event) {
//                            .mouse_motion => |motion| {
//                                const point = Point{ motion[0], properties.vpsize[1] - motion[1] };
//                                if (panel.state == .empty and isRectAroundPoint(panel.rect, point)) {
//                                    return Event{ .panel_focussed = .{ .control = control_id, .component = component_id } };
//                                } else if (panel.state != .empty and !isRectAroundPoint(panel.rect, point)) {
//                                    return Event{ .panel_unfocussed = .{ .control = control_id, .component = component_id } };
//                                }
//                            },
//                            .mouse_button_down => |button| {
//                                if (panel.state == .focus and button == .left) {
//                                    return Event{ .panel_pressed = .{ .control = control_id, .component = component_id } };
//                                }
//                            },
//                            .mouse_button_up => |button| {
//                                if (panel.state == .press and button == .left) {
//                                    return Event{ .panel_unpressed = .{ .control = control_id, .component = component_id } };
//                                }
//                            },
//                            else => {},
//                        }
//                    },
//                    else => {},
//                }
//            }
//        }
//        return null;
//    }
//};
//
//pub const Event = union(enum) {
//    panel_focussed: struct { control: ControlId, component: ComponentId },
//    panel_unfocussed: struct { control: ControlId, component: ComponentId },
//    panel_pressed: struct { control: ControlId, component: ComponentId },
//    panel_unpressed: struct { control: ControlId, component: ComponentId },
//};
//
//pub const EventSystem = struct {
//    pub fn process(controls: *Controls, event: Event) void {
//        switch (event) {
//            .panel_focussed => |id| {
//                const state: *PanelInputState = switch (controls.*.items[id.control].items[id.component]) {
//                    inline .panel_input, .panel_input_color => |*panel| &panel.state,
//                    else => @panic("Invalid component type"),
//                };
//                if (state.* == .empty) state.* = .focus;
//            },
//            .panel_unfocussed => |id| {
//                const state: *PanelInputState = switch (controls.*.items[id.control].items[id.component]) {
//                    inline .panel_input, .panel_input_color => |*panel| &panel.state,
//                    else => @panic("Invalid component type"),
//                };
//                state.* = .empty;
//            },
//            .panel_pressed => |id| {
//                const state: *PanelInputState = switch (controls.*.items[id.control].items[id.component]) {
//                    inline .panel_input, .panel_input_color => |*panel| &panel.state,
//                    else => @panic("Invalid component type"),
//                };
//                if (state.* == .focus) state.* = .press;
//            },
//            .panel_unpressed => |id| {
//                const state: *PanelInputState = switch (controls.*.items[id.control].items[id.component]) {
//                    inline .panel_input, .panel_input_color => |*panel| &panel.state,
//                    else => @panic("Invalid component type"),
//                };
//                if (state.* == .press) state.* = .focus;
//            },
//        }
//    }
//};
