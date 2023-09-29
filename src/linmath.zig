const math = @import("std").math;

pub const F32x4 = @Vector(4, f32);
pub const F32x3 = @Vector(3, f32);
pub const F32x2 = @Vector(2, f32);
pub const I32x4 = @Vector(4, i32);
pub const I32x3 = @Vector(3, i32);
pub const I32x2 = @Vector(2, i32);
pub const Mat = [4]F32x4;
pub const MatIdentity = Mat{
    .{ 1.0, 0.0, 0.0, 0.0 },
    .{ 0.0, 1.0, 0.0, 0.0 },
    .{ 0.0, 0.0, 1.0, 0.0 },
    .{ 0.0, 0.0, 0.0, 1.0 },
};
pub const Quat = F32x4;

// нормализовывание вектора
pub fn normalize(v: F32x3) F32x3 {
    const len = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    return .{ v[0] / len, v[1] / len, v[2] / len };
}

// векторное произведение
pub fn cross(v1: F32x3, v2: F32x3) F32x3 {
    return F32x3{
        v1[1] * v2[2] - v1[2] * v2[1],
        v1[0] * v2[2] - v1[2] * v2[0],
        v1[0] * v2[1] - v1[1] * v2[0],
    };
}

// матрица поворота по оси X на градус f
pub fn RotX(f: f32) Mat {
    return Mat{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, math.cos(f), -math.sin(f), 0.0 },
        .{ 0.0, math.sin(f), math.cos(f), 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

// матрица поворота по оси Y на градус f
pub fn RotY(f: f32) Mat {
    return Mat{
        .{ math.cos(f), 0.0, math.sin(f), 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ -math.sin(f), 0.0, math.cos(f), 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

// матрица поворота по оси Z на градус f
pub fn RotZ(f: f32) Mat {
    return Mat{
        .{ math.cos(f), -math.sin(f), 0.0, 0.0 },
        .{ math.sin(f), math.cos(f), 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

// матрица поворота по всем осям на градусы f
pub fn Rot(f: F32x3) Mat {
    var mat = MatIdentity;
    mat = mul(mat, RotX(f[0]));
    mat = mul(mat, RotZ(f[2]));
    return mat;
}

pub fn Pos(pos: F32x3) Mat {
    return Mat{
        .{ 1.0, 0.0, 0.0, pos[0] },
        .{ 0.0, 1.0, 0.0, pos[1] },
        .{ 0.0, 0.0, 1.0, pos[2] },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

pub fn Scale(scale: F32x3) Mat {
    return Mat{
        .{ scale[0], 0.0, 0.0, 0.0 },
        .{ 0.0, scale[1], 0.0, 0.0 },
        .{ 0.0, 0.0, scale[2], 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

// перемножение матриц
pub fn mul(m1: Mat, m2: Mat) Mat {
    var result: Mat = undefined;
    comptime var i = 0;
    inline while (i < 4) {
        comptime var j = 0;
        inline while (j < 4) {
            result[i][j] = m1[i][0] * m2[0][j] + m1[i][1] * m2[1][j] + m1[i][2] * m2[2][j] + m1[i][3] * m2[3][j];
            j += 1;
        }
        i += 1;
    }
    return result;
}
