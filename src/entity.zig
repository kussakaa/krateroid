const std = @import("std");
const Allocator = std.mem.Allocator;
const Vec3 = @import("linmath.zig").F32x3;

pub const Entity = usize;
pub const EntityManager = struct {
    allocator: Allocator,
    entities: std.AutoHashMap(Entity, Entity),

    pub fn init(allocator: Allocator) EntityManager {
        return EntityManager{
            .allocator = allocator,
            .entities = std.AutoHashMap(Entity, Entity).init(allocator),
        };
    }

    pub fn deinit(self: *EntityManager) void {
        self.entities.deinit();
    }

    pub fn addEntity(self: *EntityManager) !Entity {
        const Static = struct {
            var id = 0;
        };
        Static.id += 1;
        self.entities.put(Static.id, Static.id);
        return Static.id;
    }
};
