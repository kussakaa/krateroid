const Point = struct {
    x: i32,
    y: i32,
};

const Line = struct {
    p1: Point,
    p2: Point,
};

const Rect = struct {
    min: Point,
    max: Point,
};