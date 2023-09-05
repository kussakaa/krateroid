const c = @import("c.zig");
const std = @import("std");
const log_enable = @import("log.zig").world_log_enable;
const Allocator = std.mem.Allocator;
const linmath = @import("linmath.zig");
const Vec3 = linmath.F32x3;
const I32x2 = linmath.I32x2;

pub const Component = union(enum) {
    position: Vec3,
    rotation: Vec3,
    velocity: Vec3,
};

pub const Entity = std.ArrayListUnmanaged(Component);
pub const Entities = std.ArrayList(Entity);

pub const World = struct {
    allocator: Allocator,
    seed: u32 = 0,
    chunks: std.ArrayList(Chunk) = std.ArrayList(Chunk).init(std.heap.page_allocator),
    entities: Entities,

    pub fn init(allocator: Allocator) World {
        return World{
            .allocator = allocator,
            .chunks = std.ArrayList(Chunk).init(allocator),
            .entities = Entities.init(allocator),
        };
    }

    pub fn deinit(self: *World) void {
        self.chunks.deinit();
        for (self.entities.items) |*entity| {
            entity.deinit();
        }
        self.entities.deinit();
    }

    pub fn addChunk(self: *World, pos: I32x2) !void {
        for (self.chunks.items) |*self_chunk| {
            if (self_chunk.pos[0] == pos[0] and self_chunk.pos[1] == pos[1]) {
                return;
            }
        }

        var chunk = Chunk.init(self, pos);
        chunk.generate();

        try self.chunks.append(chunk);
    }

    pub fn getChunk(self: *World, pos: I32x2) ?*Chunk {
        for (self.chunks.items) |*chunk| {
            if (chunk.pos[0] == pos[0] and chunk.pos[1] == pos[1]) return chunk;
        }

        return null;
    }

    pub fn update(self: *World) void {
        for (self.chunks.items) |*chunk| {
            chunk.updateGrid();
        }
    }
};

pub const Chunk = struct {
    pub const width = 32;
    pub const height = 64;

    world: *World,
    pos: I32x2,
    edit: u32 = 0,
    update: u32 = 0,

    // ----------------
    // Сетка чанка
    // ----------------

    //    |   Z  ||  Y  ||  X  |
    grid: [height][width][width]Cell,

    // ---------------------------
    // Инициализация пустого чанка
    // ---------------------------
    fn init(world: *World, pos: I32x2) Chunk {
        var grid: [height][width][width]Cell = undefined;

        var z: usize = 0;
        while (z < height) : (z += 1) {
            var y: usize = 0;
            while (y < width) : (y += 1) {
                var x: usize = 0;
                while (x < width) : (x += 1) {
                    grid[z][y][x] = Cell.air;
                }
            }
        }

        return Chunk{
            .world = world,
            .pos = pos,
            .grid = grid,
        };
    }

    // ---------------------------
    // Генерация местности в чанке
    // ---------------------------
    fn generate(self: *Chunk) void {
        @setRuntimeSafety(false);
        var noise_velue = c.fnlCreateState();
        noise_velue.noise_type = c.FNL_NOISE_VALUE;
        var noise_cellular = c.fnlCreateState();
        noise_cellular.noise_type = c.FNL_NOISE_CELLULAR;

        for (0..height) |z| {
            for (0..height) |y| {
                for (0..height) |x| {
                    const velue = c.fnlGetNoise2D(
                        &noise_velue,
                        @as(f32, @floatFromInt((self.pos[0] * @as(i32, @intCast(width)) + @as(i32, @intCast(x))) * 3)),
                        @as(f32, @floatFromInt((self.pos[1] * @as(i32, @intCast(width)) + @as(i32, @intCast(y))) * 3)),
                    );

                    const cellular = c.fnlGetNoise2D(
                        &noise_cellular,
                        @as(f32, @floatFromInt((self.pos[0] * @as(i32, @intCast(width)) + @as(i32, @intCast(x))) * 3)),
                        @as(f32, @floatFromInt((self.pos[1] * @as(i32, @intCast(width)) + @as(i32, @intCast(y))) * 3)),
                    );

                    if (@as(f32, @floatFromInt(z)) < (velue + cellular) * 15.0 + 32.0) {
                        self.grid[z][y][x] = Cell.block;
                    } else {
                        self.grid[z][y][x] = Cell.air;
                    }
                }
            }
        }
    }

    // ----------------------------
    // Обновление всех клеток чанка
    // (Взрывы, летящие, сыпящиеся блоки)
    // ----------------------------------
    pub fn updateGrid(self: *Chunk) void {
        if (self.update > 0) {
            @setRuntimeSafety(false);
            for (0..height) |z| {
                for (0..height) |y| {
                    for (0..height) |x| {
                        if (self.grid[z][y][x] == Cell.explosion) {
                            var ez: usize = @max(0, @max(10, z) - 10);
                            while (ez < @min(64, z + 10)) : (ez += 1) {
                                var ey: usize = @max(0, @max(10, y) - 10);
                                while (ey < @min(32, y + 10)) : (ey += 1) {
                                    var ex: usize = @max(0, @max(10, x) - 10);
                                    while (ex < @min(32, x + 10)) : (ex += 1) {
                                        self.grid[ez][ey][ex] = Cell.air;
                                        //self.world.getChunk(.{ self.pos[0], self.pos[1] - 1 }).?.edit += 1;
                                        //self.world.getChunk(.{ self.pos[0] - 1, self.pos[1] }).?.edit += 1;
                                        self.edit += 1;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            self.update -= 1;
        }
    }
};

pub const Cell = enum {
    air, // клетка пустая
    block, // клетка это твёрдый материал
    explosion, // клетка это взрыв
};
