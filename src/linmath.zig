const math = @import("std").math;

pub const F32x4 = @Vector(4, f32);
pub const F32x3 = @Vector(3, f32);
pub const F32x2 = @Vector(2, f32);
pub const I32x4 = @Vector(4, i32);
pub const I32x3 = @Vector(3, i32);
pub const I32x2 = @Vector(2, i32);
pub const Mat = [4]F32x4;
pub const MatIdentity = Mat{
    @Vector(4, f32){ 1.0, 0.0, 0.0, 0.0 },
    @Vector(4, f32){ 0.0, 1.0, 0.0, 0.0 },
    @Vector(4, f32){ 0.0, 0.0, 1.0, 0.0 },
    @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
};
pub const Quat = F32x4;

// матрица поворота по оси X на градус f
pub fn RotX(f: f32) Mat {
    return Mat{
        @Vector(4, f32){ 1.0, 0.0, 0.0, 0.0 },
        @Vector(4, f32){ 0.0, math.cos(f), -math.sin(f), 0.0 },
        @Vector(4, f32){ 0.0, math.sin(f), math.cos(f), 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
    };
}

// матрица поворота по оси Y на градус f
pub fn RotY(f: f32) Mat {
    return Mat{
        @Vector(4, f32){ math.cos(f), 0.0, math.sin(f), 0.0 },
        @Vector(4, f32){ 0.0, 1.0, 0.0, 0.0 },
        @Vector(4, f32){ -math.sin(f), 0.0, math.cos(f), 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
    };
}

// матрица поворота по оси Z на градус f
pub fn RotZ(f: f32) Mat {
    return Mat{
        @Vector(4, f32){ math.cos(f), -math.sin(f), 0.0, 0.0 },
        @Vector(4, f32){ math.sin(f), math.cos(f), 0.0, 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 1.0, 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
    };
}

pub fn Pos(pos: F32x3) Mat {
    return Mat{
        @Vector(4, f32){ 1.0, 0.0, 0.0, 0.0 },
        @Vector(4, f32){ 0.0, 1.0, 0.0, 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 1.0, 0.0 },
        @Vector(4, f32){ pos[0], pos[1], pos[2], 1.0 },
    };
}

pub fn Scale(scale: F32x3) Mat {
    return Mat{
        @Vector(4, f32){ scale[0], 0.0, 0.0, 0.0 },
        @Vector(4, f32){ 0.0, scale[1], 0.0, 0.0 },
        @Vector(4, f32){ 0.0, 0.0, scale[2], 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
    };
}

// перемножение матриц
pub fn mul(m0: Mat, m1: Mat) Mat {
    var result: Mat = undefined;
    comptime var i = 0;
    inline while (i < 4) {
        comptime var j = 0;
        inline while (j < 4) {
            result[i][j] = m0[i][0] * m1[0][j] + m0[i][1] * m1[1][j] + m0[i][2] * m1[2][j] + m0[i][3] * m1[3][j];
            j += 1;
        }
        i += 1;
    }
    return result;
}
