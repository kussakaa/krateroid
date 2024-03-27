const zm = @import("zmath");

const Vec = zm.Vec;
const Color = Vec;

pub const debug = struct {
    pub var show_info: bool = false;
    pub var show_grid: bool = false;
};

pub const audio = struct {
    pub var volume: f32 = 0.3;
};

pub const drawer = struct {
    pub const background = struct {
        pub var color: Color = .{ 0.0, 0.0, 0.0, 1.0 };
    };
    pub const light = struct {
        pub var color: Color = .{ 1.0, 1.0, 1.0, 1.0 };
        pub var direction: Vec = .{ 1.0, 0.0, 1.0, 1.0 };
        pub var ambient: f32 = 0.4;
        pub var diffuse: f32 = 0.4;
        pub var specular: f32 = 0.1;
    };
};
