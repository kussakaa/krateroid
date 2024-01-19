pub const Vec = @Vector(4, f32);
pub const Mat = [4]@Vector(4, f32);

pub inline fn identity(comptime T: type) T {
    return switch (T) {
        Mat => .{
            .{ 1.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 1.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 1.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        },
        else => @compileError("linmath.identity() not implemented for type: " ++ @typeName(T)),
    };
}

pub inline fn zero(comptime T: type) T {
    return switch (T) {
        Vec => .{ 0.0, 0.0, 0.0, 0.0 },
        Mat => .{
            .{ 0.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 0.0 },
        },
        else => @compileError("linmath.zero() not implemented for type: " ++ @typeName(T)),
    };
}

pub inline fn cross(v0: Vec, v1: Vec) Vec {
    var xmm0 = swizzle(v0, .y, .z, .x, .w);
    var xmm1 = swizzle(v1, .z, .x, .y, .w);
    const result = xmm0 * xmm1;
    xmm0 = swizzle(xmm0, .y, .z, .x, .w);
    xmm1 = swizzle(xmm1, .z, .x, .y, .w);
    return result - xmm0 * xmm1;
}

pub inline fn scale(v: Vec) Mat {
    return .{
        .{ v[0], 0.0, 0.0, 0.0 },
        .{ 0.0, v[1], 0.0, 0.0 },
        .{ 0.0, 0.0, v[2], 0.0 },
        .{ 0.0, 0.0, 0.0, v[3] },
    };
}

pub inline fn transform(v: Vec) Mat {
    return .{
        .{ 1.0, 0.0, 0.0, -v[0] },
        .{ 0.0, 1.0, 0.0, -v[1] },
        .{ 0.0, 0.0, 1.0, -v[2] },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

pub inline fn rotateX(f: f32) Mat {
    return .{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, @cos(f), -@sin(f), 0.0 },
        .{ 0.0, @sin(f), @cos(f), 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

pub inline fn rotateY(f: f32) Mat {
    return .{
        .{ @cos(f), 0.0, @sin(f), 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ -@sin(f), 0.0, @cos(f), 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

pub inline fn rotateZ(f: f32) Mat {
    return .{
        .{ @cos(f), -@sin(f), 0.0, 0.0 },
        .{ @sin(f), @cos(f), 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

pub inline fn mul(a: anytype, b: anytype) MulRetType(@TypeOf(a), @TypeOf(b)) {
    const Ta = @TypeOf(a);
    const Tb = @TypeOf(b);
    if (Ta == Mat and Tb == Mat) {
        return matMulMat(a, b);
    } else {
        @compileError("linmath.mul() not implemented for types: " ++ @typeName(Ta) ++ ", " ++ @typeName(Tb));
    }
}

fn MulRetType(comptime Ta: type, comptime Tb: type) type {
    if (Ta == Mat and Tb == Mat) {
        return Mat;
    } else {
        @compileError("linmath.mul() not implemented for types: " ++ @typeName(Ta) ++ @typeName(Tb));
    }
}

fn matMulMat(m0: Mat, m1: Mat) Mat {
    var result: Mat = undefined;
    inline for (0..4) |row| {
        const vx = swizzle(m0[row], .x, .x, .x, .x);
        const vy = swizzle(m0[row], .y, .y, .y, .y);
        const vz = swizzle(m0[row], .z, .z, .z, .z);
        const vw = swizzle(m0[row], .w, .w, .w, .w);
        result[row] = @mulAdd(Vec, vx, m1[0], vz * m1[2]) + @mulAdd(Vec, vy, m1[1], vw * m1[3]);
    }
    return result;
}

fn vecMulMat(v: Vec, m: Mat) Vec {
    const vx = @shuffle(f32, v, undefined, [4]i32{ 0, 0, 0, 0 });
    const vy = @shuffle(f32, v, undefined, [4]i32{ 1, 1, 1, 1 });
    const vz = @shuffle(f32, v, undefined, [4]i32{ 2, 2, 2, 2 });
    const vw = @shuffle(f32, v, undefined, [4]i32{ 3, 3, 3, 3 });
    return vx * m[0] + vy * m[1] + vz * m[2] + vw * m[3];
}

const VecComponent = enum { x, y, z, w };

inline fn swizzle(
    v: Vec,
    comptime x: VecComponent,
    comptime y: VecComponent,
    comptime z: VecComponent,
    comptime w: VecComponent,
) Vec {
    return @shuffle(f32, v, undefined, [4]i32{ @intFromEnum(x), @intFromEnum(y), @intFromEnum(z), @intFromEnum(w) });
}
