pub const Vec = @Vector(4, f32);
pub const VecComponent = enum { x, y, z, w };
pub const Mat = [4]Vec;
pub const Quat = Vec;

pub inline fn identity(comptime T: type) T {
    return switch (T) {
        Mat => .{
            .{ 1.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 1.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 1.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        },
        Vec => .{ 1.0, 1.0, 1.0, 1.0 },
        else => T{},
    };
}

pub inline fn zero(comptime T: type) T {
    return switch (T) {
        Mat => .{
            .{ 0.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 0.0 },
        },
        Vec => .{ 0.0, 0.0, 0.0, 0.0 },
        else => T{},
    };
}

pub inline fn swizzle(
    v: Vec,
    comptime x: VecComponent,
    comptime y: VecComponent,
    comptime z: VecComponent,
    comptime w: VecComponent,
) Vec {
    return @shuffle(f32, v, undefined, [4]i32{ @intFromEnum(x), @intFromEnum(y), @intFromEnum(z), @intFromEnum(w) });
}

//pub fn mul(a: anytype, b: anytype) anytype {
//
//}

fn mulMat(m0: Mat, m1: Mat) Mat {
    var result: Mat = undefined;
    comptime var row: u32 = 0;
    inline while (row < 4) : (row += 1) {
        const vx = swizzle(m0[row], .x, .x, .x, .x);
        const vy = swizzle(m0[row], .y, .y, .y, .y);
        const vz = swizzle(m0[row], .z, .z, .z, .z);
        const vw = swizzle(m0[row], .w, .w, .w, .w);
        result[row] = @mulAdd(f32, vx, m1[0], vz * m1[2]) + @mulAdd(f32, vy, m1[1], vw * m1[3]);
    }
    return result;
}
