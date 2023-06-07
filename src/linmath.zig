const math = @import("std").math;

pub const F32x4 = @Vector(4, f32);
pub const Vec4 = F32x4;
pub const Mat4 = [4]F32x4;
pub const Mat4identity = Mat4{
    @Vector(4, f32){ 1.0, 0.0, 0.0, 0.0 },
    @Vector(4, f32){ 0.0, 1.0, 0.0, 0.0 },
    @Vector(4, f32){ 0.0, 0.0, 1.0, 0.0 },
    @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
};
pub const Quat = F32x4;

pub fn rotz(angle: f32) Mat4 {
    return Mat4{
        @Vector(4, f32){ math.cos(angle), -math.sin(angle), 0.0, 0.0 },
        @Vector(4, f32){ math.sin(angle), math.cos(angle), 0.0, 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 1.0, 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
    };
}

pub fn rotz(angle: f32) Mat4 {
    return Mat4{
        @Vector(4, f32){ math.cos(angle), -math.sin(angle), 0.0, 0.0 },
        @Vector(4, f32){ math.sin(angle), math.cos(angle), 0.0, 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 1.0, 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
    };
}

pub fn rotz(angle: f32) Mat4 {
    return Mat4{
        @Vector(4, f32){ math.cos(angle), -math.sin(angle), 0.0, 0.0 },
        @Vector(4, f32){ math.sin(angle), math.cos(angle), 0.0, 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 1.0, 0.0 },
        @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
    };
}
