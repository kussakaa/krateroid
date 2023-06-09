pub const Point = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Point {
        return Point{
            .x = x,
            .y = y,
        };
    }
};

pub const Line = struct {
    p1: Point,
    p2: Point,

    pub fn init(p1: Point, p2: Point) Line {
        return Line{
            .p1 = p1,
            .p2 = p2,
        };
    }
};

pub const Rect = struct {
    min: Point,
    max: Point,

    pub fn init(pos: Point, size: Point) Rect {
        return Rect{
            .min = pos,
            .max = .{ .x = pos.x + size.x, .y = pos.y + size.y },
        };
    }
};
