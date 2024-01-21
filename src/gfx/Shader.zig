const std = @import("std");
const gl = @import("zopengl");

const log = std.log.scoped(.gfx);
const Allocator = std.mem.Allocator;

const Type = enum(u32) {
    vertex = gl.VERTEX_SHADER,
    fragment = gl.FRAGMENT_SHADER,
};

const Self = @This();
id: u32, // индекс шейдера

pub fn init(
    shader_source: []const u8,
    shader_type: Type,
    allocator: Allocator,
) !Self {
    const id = gl.createShader(@intFromEnum(shader_type));
    gl.shaderSource(id, 1, &shader_source.ptr, @ptrCast(&.{@as(gl.Int, @intCast(shader_source.len))}));
    gl.compileShader(id);

    var succes: i32 = 1;
    gl.getShaderiv(id, gl.COMPILE_STATUS, &succes);

    // вывод ошибки если шейдер не скомпилировался
    if (succes == 0) {
        var info_log_len: i32 = 0;
        gl.getShaderiv(id, gl.INFO_LOG_LENGTH, &info_log_len);
        const info_log = try allocator.alloc(u8, @as(usize, @intCast(info_log_len)));
        defer allocator.free(info_log);
        gl.getShaderInfoLog(id, info_log_len, null, info_log.ptr);
        log.err("shader {} compilation failed: {s}\n", .{ id, info_log });
        return error.ShaderCompilation;
    }

    const self = Self{ .id = id };
    log.debug("init {}", .{self});
    return self;
}

pub fn deinit(self: Self) void {
    log.debug("deinit {}", .{self});
    gl.deleteShader(self.id);
}

pub fn initFormFile(
    shader_path: []const u8,
    shader_type: Type,
    allocator: std.mem.Allocator,
) !Self {
    const cwd = std.fs.cwd();
    const data = try cwd.readFileAlloc(allocator, shader_path, 100_000_000);
    defer allocator.free(data);
    return Self.init(data[0..], shader_type, allocator);
}
