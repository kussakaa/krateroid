const config = @import("config.zig");

pub const lines = @import("shape/lines.zig");

const axis = struct {
    const x = 0;
    const y = 1;
    const z = 2;
};

pub fn init() void {
    lines.init();

    // X
    lines.add(axis.x, .{
        .v1 = .{ 0.0, 0.0, 0.0, 1.0 },
        .v2 = .{ 32.0, 0.0, 0.0, 1.0 },
        .c1 = .{ 1.0, 0.5, 0.5, 1.0 },
        .c2 = .{ 1.0, 0.5, 0.5, 1.0 },
    });

    // Y
    lines.add(axis.y, .{
        .v1 = .{ 0.0, 0.0, 0.0, 1.0 },
        .v2 = .{ 0.0, 32.0, 0.0, 1.0 },
        .c1 = .{ 0.5, 1.0, 0.5, 1.0 },
        .c2 = .{ 0.5, 1.0, 0.5, 1.0 },
    });

    // Z
    lines.add(axis.z, .{
        .v1 = .{ 0.0, 0.0, 0.0, 1.0 },
        .v2 = .{ 0.0, 0.0, 32.0, 1.0 },
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
