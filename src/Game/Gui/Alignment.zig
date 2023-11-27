const Point = @Vector(2, i32);
const Size = @Vector(2, i32);
const Rect = @import("Rect.zig");

const Alignment = @This();
horizontal: Horizontal = .left,
vertical: Vertical = .top,

pub fn transform(alignment: Alignment, obj: anytype, vpsize: Point) @TypeOf(obj) {
    return switch (comptime @TypeOf(obj)) {
        Point => alignment.transformPoint(obj, vpsize),
        Rect => .{
            .min = alignment.transformPoint(obj.min, vpsize),
            .max = alignment.transformPoint(obj.max, vpsize),
        },
        else => @compileError("invalid type for gui.Alignment.transform()"),
    };
}

fn transformPoint(alignment: Alignment, point: Point, vpsize: Point) Point {
    var result: Point = point;
    switch (alignment.horizontal) {
        .left => {},
        .center => result[0] = @divTrunc(vpsize[0], 2) + point[0],
        .right => result[0] = vpsize[0] + point[0],
    }
    switch (alignment.vertical) {
        .top => {},
        .center => result[1] = @divTrunc(vpsize[1], 2) + point[1],
        .bottom => result[1] = vpsize[1] + point[1],
    }
    return result;
}

const Horizontal = enum { left, center, right };
const Vertical = enum { bottom, center, top };
