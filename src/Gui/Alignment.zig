const Point = @Vector(2, i32);
const Size = @Vector(2, i32);
const Rect = @import("Rect.zig");

const H = enum { left, center, right };
const V = enum { bottom, center, top };

const Self = @This();
h: H = .left,
v: V = .top,

pub fn transform(self: Self, obj: anytype, vpsize: Point) @TypeOf(obj) {
    return switch (comptime @TypeOf(obj)) {
        Point => self.transformPoint(obj, vpsize),
        Rect => .{
            .min = self.transformPoint(obj.min, vpsize),
            .max = self.transformPoint(obj.max, vpsize),
        },
        else => @compileError("invalid type for gui.Alignment.transform()"),
    };
}

inline fn transformPoint(self: Self, point: Point, vpsize: Point) Point {
    return .{
        switch (self.h) {
            .left => point[0],
            .center => @divTrunc(vpsize[0], 2) + point[0],
            .right => vpsize[0] + point[0],
        },
        switch (self.v) {
            .top => point[1],
            .center => @divTrunc(vpsize[1], 2) + point[1],
            .bottom => vpsize[1] + point[1],
        },
    };
}
