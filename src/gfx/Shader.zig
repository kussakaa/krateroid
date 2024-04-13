const std = @import("std");
const log = std.log.scoped(.gfx);

const Allocator = std.mem.Allocator;

const gl = @import("zopengl").bindings;

pub const Type = enum(u32) {
    vert = gl.VERTEX_SHADER,
    frag = gl.FRAGMENT_SHADER,
};

const Id = gl.Uint;
const Self = @This();

id: Id,

pub fn init(
    comptime name: []const u8,
    comptime shader_type: Type,
) !Self {
    const id = gl.createShader(@intFromEnum(shader_type));

    const prefix = "data/shader/";
    const postfix = comptime switch (shader_type) {
        .vert => "/vert.glsl",
        .frag => "/frag.glsl",
    };

    const s = struct {
        /// buffer for shader data and log loading without allocator
        var buffer = [1]u8{0} ** 100_000_000;
    };

    const data = try std.fs.cwd().readFile(prefix ++ name ++ postfix, s.buffer[0..]);

    gl.shaderSource(id, 1, &data.ptr, @alignCast(@ptrCast(&.{@as(gl.Int, @intCast(data.len))})));
    gl.compileShader(id);

    // error catching
    var succes: gl.Int = 1;
    gl.getShaderiv(id, gl.COMPILE_STATUS, &succes);
    if (succes == 0) {
        var info_log_len: gl.Int = 0;
        gl.getShaderiv(id, gl.INFO_LOG_LENGTH, &info_log_len);
        const len: usize = @intCast(info_log_len);
        gl.getShaderInfoLog(id, info_log_len, null, s.buffer[0..len].ptr);
        log.err("shader {s} failed compilation: \n{s}\n", .{ name, s.buffer[0..len] });
        return error.ShaderCompilation;
    }

    return .{ .id = id };
}

pub fn deinit(self: Self) void {
    gl.deleteShader(self.id);
}
