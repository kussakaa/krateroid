const std = @import("std");
const Allocator = std.mem.Allocator;
const Entity = @import("entity.zig").Entity;

const Vec3 = @import("linmath.zig").F32x3;

pub const Position = struct { data: Vec3 };
pub const Rotation = struct { data: Vec3 };
pub const Velocity = struct { data: Vec3 };

pub const Manager = struct {
    allocator: Allocator,
    components: struct {
        position: std.AutoHashMap(Entity, Position),
        rotation: std.AutoHashMap(Entity, Rotation),
        velocity: std.AutoHashMap(Entity, Velocity),
    },

    pub fn init(allocator: Allocator) Manager {
        return Manager{
            .allocator = allocator,
            .components = .{
                .position = std.AutoHashMap(Entity, Position).init(allocator),
                .rotation = std.AutoHashMap(Entity, Rotation).init(allocator),
                .velocity = std.AutoHashMap(Entity, Velocity).init(allocator),
            },
        };
    }

    pub fn deinit(self: *Manager) void {
        self.components.position.deinit();
        self.components.rotation.deinit();
        self.components.velocity.deinit();
    }
};
