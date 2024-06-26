const config = @import("config.zig");

pub const line = @import("shape/line.zig");
pub const lines = @import("shape/lines.zig");

const axis = struct {
    const x: line.Id = 0;
    const y: line.Id = 1;
    const z: line.Id = 2;
};

pub fn init() void {
    lines.init();

    // X
    lines.add(axis.x, .{
        .v1 = .{ 0.0, 0.0, 0.0, 1.0 },
        .v2 = .{ 16.0, 0.0, 0.0, 1.0 },
        .c1 = .{ 1.0, 0.5, 0.5, 1.0 },
        .c2 = .{ 1.0, 0.5, 0.5, 1.0 },
    });

    // Y
    lines.add(axis.y, .{
        .v1 = .{ 0.0, 0.0, 0.0, 1.0 },
        .v2 = .{ 0.0, 16.0, 0.0, 1.0 },
        .c1 = .{ 0.5, 1.0, 0.5, 1.0 },
        .c2 = .{ 0.5, 1.0, 0.5, 1.0 },
    });

    // Z
    lines.add(axis.z, .{
        .v1 = .{ 0.0, 0.0, 0.0, 1.0 },
        .v2 = .{ 0.0, 0.0, 64.0, 1.0 },
        .c1 = .{ 0.5, 0.5, 1.0, 1.0 },
        .c2 = .{ 0.5, 0.5, 1.0, 1.0 },
    });
}

pub fn deinit() void {}

pub fn update() void {
    lines.show(axis.x, config.debug.show_info);
    lines.show(axis.y, config.debug.show_info);
    lines.show(axis.z, config.debug.show_info);
}
