pub const actors = @import("entity/actors.zig");
pub const bullets = @import("entity/bullets.zig");

pub fn init() void {
    actors.init();
    bullets.init();
}

pub fn deinit() void {
    actors.deinit();
    bullets.deinit();
}

pub fn update() void {
    actors.update();
    bullets.update();
}
