const std = @import("std");
const Allocator = std.mem.Allocator;
const Vec3 = @import("linmath.zig").F32x3;

pub const Component = union(enum) {
    position: Vec3,
    rotation: Vec3,
    velocity: Vec3,
};

pub const Entity = std.ArrayList(Component);
pub const Entities = std.ArrayList(Entity);
