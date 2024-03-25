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
    allocator: Allocator,
    path: []const u8,
    shadertype: Type,
) !Self {
    const data = try std.fs.cwd().readFileAlloc(allocator, path, 100_000_000);
    defer allocator.free(data);
    const id = gl.createShader(@intFromEnum(shadertype));
    gl.shaderSource(id, 1, &data.ptr, @ptrCast(&.{@as(gl.Int, @intCast(data.len))}));
    gl.compileShader(id);

    // error catching
    var succes: gl.Int = 1;
    gl.getShaderiv(id, gl.COMPILE_STATUS, &succes);
    if (succes == 0) {
        var info_log_len: gl.Int = 0;
        gl.getShaderiv(id, gl.INFO_LOG_LENGTH, &info_log_len);
        const info_log = try allocator.alloc(u8, @intCast(info_log_len));
        defer allocator.free(info_log);
        gl.getShaderInfoLog(id, info_log_len, null, info_log.ptr);
        log.err("shader {} failed compilation: {s}\n", .{ id, info_log });
        return error.ShaderCompilation;
    }

    return .{ .id = id };
}

pub fn deinit(self: Self) void {
    gl.deleteShader(self.id);
}
