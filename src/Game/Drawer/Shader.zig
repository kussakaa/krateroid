const std = @import("std");
const log = std.log.scoped(.Shader);
const c = @import("../../c.zig");

const Shader = @This();

fn glGetError() !void {
    switch (c.glGetError()) {
        0 => {},
        else => return error.GLError,
    }
}

pub const Type = enum {
    vertex,
    fragment,
};

id: u32, // индекс шейдера

pub fn initFormFile(allocator: std.mem.Allocator, shader_path: []const u8, shader_type: Type) !Shader {
    const cwd = std.fs.cwd();
    var file = try cwd.openFile(shader_path, .{});
    defer file.close();
    const reader = file.reader();
    var buffer: [8192]u8 = undefined;
    const len = try reader.readAll(&buffer);
    return Shader.init(allocator, buffer[0..len], shader_type);
}

pub fn init(allocator: std.mem.Allocator, shader_source: []const u8, shader_type: Type) !Shader {
    const id = switch (shader_type) {
        Type.vertex => c.glCreateShader(c.GL_VERTEX_SHADER),
        Type.fragment => c.glCreateShader(c.GL_FRAGMENT_SHADER),
    };

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
        log.err("shader {} compilation: <r>{s}\n", .{ id, info_log });
        return error.ShaderCompilation;
    }

    const shader = Shader{ .id = id };
    log.debug("init {}", .{shader});
    return shader;
}
