const std = @import("std");
const Allocator = std.mem.Allocator;
const Vec3 = @import("linmath.zig").F32x3;

pub const Id = usize;
pub const Manager = struct {
    allocator: Allocator,
    entities: std.AutoHashMap(Id, Id),

    pub fn init(allocator: Allocator) Manager {
        return Manager{
            .allocator = allocator,
            .entities = std.AutoHashMap(Id, Id).init(allocator),
        };
    }

    pub fn deinit(self: *Manager) void {
        self.entities.deinit();
    }

    pub fn addEntity(self: *Manager) !Id {
        const Static = struct {
            var id = 0;
        };
        Static.id += 1;
        self.entities.put(Static.id, Static.id);
        return Static.id;
    }

    pub fn removeEntity(self: *Manager, id: Id) void {
        self.entities.remove(id);
    }
};
