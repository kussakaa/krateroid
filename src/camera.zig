const linmath = @import("linmath.zig");
const Vec3 = linmath.F32x3;
const Mat = linmath.Mat;

pub const Camera = struct {
    pos: Vec3 = Vec3{ 0.0, 0.0, 0.0 },
    rot: Vec3 = Vec3{ 0.0, 0.0, 0.0 },
    ratio: f32 = 1.0,
    zoom: f32 = 1.0,

    view: Mat = linmath.MatIdentity,
    proj: Mat = linmath.MatIdentity,

    pub fn update_proj(self: *Camera) void {
        self.proj = linmath.Scale(.{
            self.ratio,
            1.0,
            -0.0001,
        });
    }

    pub fn update_view(self: *Camera) void {
        self.view = linmath.MatIdentity;
        self.view = linmath.mul(self.view, linmath.Scale(.{
            self.zoom,
            self.zoom,
            1.0,
        }));
        self.view = linmath.mul(self.view, linmath.Rot(self.rot));
        self.view = linmath.mul(self.view, linmath.Pos(-self.pos));
    }

    pub fn update(self: *Camera) void {
        self.update_proj();
        self.update_view();
    }
};
