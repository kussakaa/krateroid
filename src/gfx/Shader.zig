const std = @import("std");
const log = std.log.scoped(.gfx);
const Allocator = std.mem.Allocator;
const c = @import("../c.zig");

const Type = enum(u32) {
    vertex = c.GL_VERTEX_SHADER,
    fragment = c.GL_FRAGMENT_SHADER,
};

const Self = @This();
id: u32, // индекс шейдера

pub fn init(
    shader_source: []const u8,
    shader_type: Type,
    allocator: Allocator,
) !Self {
    const id = c.glCreateShader(@intFromEnum(shader_type));
    c.glShaderSource(id, 1, &shader_source.ptr, @ptrCast(&.{@as(c.GLint, @intCast(shader_source.len))}));
    c.glCompileShader(id);

    var succes: i32 = 1;
    c.glGetShaderiv(id, c.GL_COMPILE_STATUS, &succes);

    // вывод ошибки если шейдер не скомпилировался
    if (succes == 0) {
        var info_log_len: i32 = 0;
        c.glGetShaderiv(id, c.GL_INFO_LOG_LENGTH, &info_log_len);
        const info_log = try allocator.alloc(u8, @as(usize, @intCast(info_log_len)));
        defer allocator.free(info_log);
        c.glGetShaderInfoLog(id, info_log_len, null, info_log.ptr);
        log.err("shader {} compilation failed: {s}\n", .{ id, info_log });
        return error.ShaderCompilation;
    }

    const self = Self{ .id = id };
    log.debug("init {}", .{self});
    return self;
}

pub fn deinit(self: Self) void {
    log.debug("deinit {}", .{self});
    c.glDeleteShader(self.id);
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
