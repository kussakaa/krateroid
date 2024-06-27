id: Id,

pub fn init(config: Config) anyerror!Shader {
    const allocator = config.allocator;
    const name = config.name;

    const id = gl.createShader(@intFromEnum(config.shader_type));

    const prefix = "data/shader/";
    const postfix = switch (config.shader_type) {
        .vert => "/vert.glsl",
        .frag => "/frag.glsl",
    };
    const path = try std.mem.concat(allocator, u8, &.{ prefix, name, postfix });
    defer allocator.free(path);

    const data = try cwd.readFileAlloc(allocator, path, 100_000_000);
    defer allocator.free(data);

    gl.shaderSource(id, 1, &data.ptr, @alignCast(@ptrCast(&.{@as(gl.Int, @intCast(data.len))})));
    gl.compileShader(id);

    // error catching
    var succes: gl.Int = 1;
    gl.getShaderiv(id, gl.COMPILE_STATUS, &succes);
    if (succes == 0) {
        var info_log_len: gl.Int = 0;
        gl.getShaderiv(id, gl.INFO_LOG_LENGTH, &info_log_len);
        const info_log_data = try allocator.alloc(u8, @intCast(info_log_len));
        defer allocator.free(info_log_data);
        gl.getShaderInfoLog(id, info_log_len, null, info_log_data[0..].ptr);
        log.failed("Initialization GFX Shader name:{s} id:{} log:\n{s}", .{ name, id, info_log_data[0..] });
        return Error.Compilation;
    }

    return .{ .id = id };
}

pub fn deinit(self: Shader) void {
    gl.deleteShader(self.id);
}

const Shader = @This();

const Config = struct {
    allocator: Allocator = std.heap.page_allocator,
    name: []const u8,
    shader_type: Type,
};

pub const Error = error{
    Compilation,
};

pub const Type = enum(u32) {
    vert = gl.VERTEX_SHADER,
    frag = gl.FRAGMENT_SHADER,
};

const Id = gl.Uint;
const Allocator = std.mem.Allocator;

const gl = @import("zopengl").bindings;

const std = @import("std");
const cwd = std.fs.cwd();
const log = @import("../log.zig");
