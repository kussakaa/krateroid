const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const F32x3 = @Vector(3, f32);

const EntityId = usize;
const Entity = struct {
    id: EntityId = 0,
    components: std.ArrayList(Component),

    fn init(allocator: Allocator, id: EntityId) Entity {
        return Entity{
            .id = id,
            .components = std.ArrayList(Component).init(allocator),
        };
    }

    fn addComponent(self: *Entity, component: Component) !void {
        try self.components.append(component);
    }
};

const EntityManager = struct {
    allocator: Allocator,
    entities: std.AutoArrayHashMap(EntityId, Entity),

    fn init(allocator: Allocator) EntityManager {
        return .{
            .allocator = allocator,
            .entities = std.AutoArrayHashMap(EntityId, Entity).init(allocator),
        };
    }

    fn addEntity(self: *EntityManager) !EntityId {
        const S = struct {
            var id: EntityId = 0;
        };

        S.id += 1;
        try self.entities.put(S.id, Entity.init(self.allocator, S.id));

        return S.id;
    }

    fn getEntity(self: *EntityManager, id: EntityId) ?*Entity {
        return self.entities.getPtr(id);
    }
};

const Component = union(enum) {
    position: linmath.F32x3,
    rotation: linmath.F32x3,
    velocity: linmath.F32x3,
};
