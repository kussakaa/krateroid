const linmath = @import("linmath.zig").linmath;

pub const Entity = struct {
    position: linmath.F32x3,
    rotation: linmath.F32x3,
    velocity: linmath.F32x3,
};

var entities: MultiArrayList(Entity) = .{};

pub const System = struct {};
