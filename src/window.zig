const std = @import("std");
const log = std.log.scoped(.window);
const sdl = @import("zsdl");
const gl = @import("zopengl");
const Allocator = std.mem.Allocator;

const zm = @import("zmath");
const Pos = @Vector(2, i32);
const Size = @Vector(2, i32);
const Color = @Vector(4, f32);

var handle: *sdl.Window = undefined;
var gl_context: sdl.gl.Context = undefined;
pub var title: [:0]const u8 = undefined;
pub var size: Size = undefined;
pub var ratio: f32 = undefined;
pub var time: u64 = 0;
pub var fps: u64 = 0;
pub var dt: f32 = 0.0;

pub fn init(info: struct {
    title: [:0]const u8 = "window",
    size: Size = .{ 800, 600 },
}) !void {
    try sdl.init(.{ .audio = true, .video = true, .events = true });

    try sdl.gl.setAttribute(.context_profile_mask, @intFromEnum(sdl.gl.Profile.core));
    try sdl.gl.setAttribute(.context_major_version, 3);
    try sdl.gl.setAttribute(.context_minor_version, 3);
    try sdl.gl.setAttribute(.context_flags, @as(i32, @bitCast(sdl.gl.ContextFlags{})));
    try sdl.gl.setAttribute(.multisamplebuffers, 1);
    try sdl.gl.setAttribute(.multisamplesamples, 4);

    title = info.title;
    size = info.size;
    ratio = @as(f32, @floatFromInt(size[0])) / @as(f32, @floatFromInt(size[1]));
    handle = try sdl.Window.create(
        title,
        sdl.Window.pos_centered,
        sdl.Window.pos_centered,
        size[0],
        size[1],
        .{
            .opengl = true,
            .resizable = true,
            //.allow_highdpi = true,
        },
    );

    gl_context = try sdl.gl.createContext(handle);
    try sdl.gl.makeCurrent(handle, gl_context);
    try sdl.gl.setSwapInterval(0);

    try gl.loadCoreProfile(sdl.gl.getProcAddress, 3, 3);

    gl.viewport(0, 0, size[0], size[1]);
    log.debug("init {s}:{}", .{ title, size });
}

pub fn deinit() void {
    log.debug("deinit {s}:{}", .{ title, size });
    handle.destroy();
    sdl.gl.deleteContext(gl_context);
}

pub fn clear(info: struct {
    color: Color = .{ 0.0, 0.0, 0.0, 1.0 },
}) void {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.clearColor(info.color[0], info.color[1], info.color[2], info.color[3]);
}

pub fn swap() void {
    const ltime = time;
    time = sdl.getPerformanceCounter();
    const pf = sdl.getPerformanceFrequency();

    dt = @floatCast(@as(f64, @floatFromInt(time - ltime)) / @as(f64, @floatFromInt(pf)));

    const s = struct {
        var sec_cntr: u64 = 0;
        var fps_cntr: u64 = 0;
    };

    s.fps_cntr += 1;

    if (time - s.sec_cntr * pf > pf) {
        fps = s.fps_cntr;
        s.fps_cntr = 0;
        s.sec_cntr += 1;
    }

    sdl.gl.swapWindow(handle);
}

pub fn resize(psize: Size) void {
    size = psize;
    ratio = @as(f32, @floatFromInt(size[0])) / @as(f32, @floatFromInt(size[1]));
    gl.viewport(0, 0, size[0], size[1]);
}
