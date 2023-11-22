const Point = @Vector(2, i32);
const Size = @Vector(2, i32);
const Rect = @import("Rect.zig");

const Alignment = @This();

const Horizontal = enum { left, center, right };
const Vertical = enum { bottom, center, top };

horizontal: Horizontal = .left,
vertical: Vertical = .top,

pub fn trasform(self: Alignment, obj: anytype, vpsize: Point) @TypeOf(obj) {
    return switch (comptime @TypeOf(obj)) {
        Point => self.transformPoint(obj, vpsize),
        Rect => .{
            .min = self.transformPoint(obj.min, vpsize),
            .max = self.transformPoint(obj.max, vpsize),
        },
        else => @compileError("invalid type for gui.Alignment.transform()"),
    };
}

fn transformPoint(self: Alignment, point: Point, vpsize: Point) Point {
    var result: Point = point;
    switch (self.horizontal) {
        .left => {},
        .center => result[0] = @divTrunc(vpsize[0], 2) + point[0],
        .right => result[0] = vpsize[0] + point[0],
    }
    switch (self.vertical) {
        .top => {},
        .center => result[1] = @divTrunc(vpsize[1], 2) + point[1],
        .bottom => result[1] = vpsize[1] + point[1],
    }
    return result;
}
