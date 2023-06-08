pub const Point = struct {
    x: i32,
    y: i32,
};

pub const Line = struct {
    p1: Point,
    p2: Point,
};

pub const Rect = struct {
    min: Point,
    max: Point,
};
