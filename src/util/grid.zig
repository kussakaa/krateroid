const testing = @import("std").testing;

pub fn Grid(
    comptime T: type,
    comptime size_x: comptime_int,
    comptime size_y: comptime_int,
    comptime size_z: comptime_int,
) type {
    return struct {
        pub const Id = usize;
        pub const Pos = @Vector(3, u32);
        pub const Size = @Vector(3, u32);

        pub const size = Size{ size_x, size_y, size_z };
        pub const volume = size[0] * size[1] * size[2];

        const Self = @This();

        data: [volume]T,

        pub fn init(zero: T) Self {
            var result: Self = undefined;
            @memset(result.data[0..], zero);
            return result;
        }

        pub inline fn get(self: Self, pos: Pos) T {
            return self.data[idFromPos(pos)];
        }

        pub inline fn set(self: *Self, pos: Pos, item: T) void {
            self.data[idFromPos(pos)] = item;
        }

        pub inline fn idFromPos(pos: Pos) Id {
            return pos[0] + pos[1] * size[0] + pos[2] * size[0] * size[1];
        }

        //pub inline fn posFromId(id: Id) Pos {
        //    return .{
        //        @rem(id, size[0]),
        //        @rem(@divTrunc(id, size[0]), size[1]),
        //        @divTrunc(@divTrunc(id, size[0]), size[1]),
        //    };
        //}
    };
}

test "util.Grid" {
    var grid = Grid(?u8, 32, 16, 2).init(null);

    grid.set(.{ 3, 1, 0 }, 2);
    grid.set(.{ 8, 8, 1 }, 0);
    grid.set(.{ 31, 15, 0 }, 52);
    grid.set(.{ 31, 5, 1 }, 7);

    try testing.expectEqual(grid.get(.{ 0, 0, 0 }), null);
    try testing.expectEqual(grid.get(.{ 31, 15, 1 }), null);
    try testing.expectEqual(grid.get(.{ 3, 1, 0 }), 2);
    try testing.expectEqual(grid.get(.{ 8, 8, 1 }), 0);
    try testing.expectEqual(grid.get(.{ 31, 15, 0 }), 52);
    try testing.expectEqual(grid.get(.{ 31, 5, 1 }), 7);
}
