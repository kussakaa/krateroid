const Point = @Vector(2, i32);
const Self = @This();

min: Point,
max: Point,

pub fn size(self: Self) Point {
    return self.max - self.min;
}

pub fn vector(self: Self) @Vector(4, i32) {
    return .{
        self.min[0],
        self.min[1],
        self.max[0],
        self.max[1],
    };
}

pub fn scale(self: Self, s: i32) Self {
    return .{
        .min = .{ self.min[0] * s, self.min[1] * s },
        .max = .{ self.max[0] * s, self.max[1] * s },
    };
}

pub fn isAroundPoint(self: Self, point: Point) bool {
    if (self.min[0] <= point[0] and self.max[0] >= point[0] and self.min[1] <= point[1] and self.max[1] >= point[1]) {
        return true;
    } else {
        return false;
    }
}
