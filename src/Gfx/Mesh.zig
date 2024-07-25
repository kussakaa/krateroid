id: Id,
name: []const u8,
buffers: []const Buffer,
ebo: ?Buffer,

pub const Config = struct {
    name: []const u8,
    buffers: []const Buffer.Config,
    vertcnt: VertCnt,
    drawmode: DrawMode = .triangles,
    ebo: ?Buffer.Config = null,
};

pub fn init(allocator: Allocator, config: Config) !Self {
    var id: Id = undefined;
    gl.genVertexArrays(1, &id);
    gl.bindVertexArray(id);

    for (0..config.buffers.len) |i| {
        const buffer = Buffer.init(config.buffers[i]);
        gl.bindBuffer(@intFromEnum(config.buffers.target), buffer.id);
        gl.enableVertexAttribArray(@intCast(i));
        gl.vertexAttribPointer(@intCast(i), buffer.vertsize, @intFromEnum(buffer.datatype), gl.FALSE, 0, null);
    }

    return .{
        .id = id,
        .name = info.name,
        .vertcnt = info.vertcnt,
        .drawmode = info.drawmode,
        .ebo = info.ebo,
    };
}

pub fn deinit(self: Self) void {
    gl.deleteVertexArrays(1, &self.id);
}

pub fn draw(self: Self) void {
    gl.bindVertexArray(self.id);
    if (self.ebo) |ebo| {
        gl.bindBuffer(@intFromEnum(ebo.target), ebo.id);
        gl.drawElements(@intFromEnum(self.drawmode), self.vertcnt, @intFromEnum(ebo.datatype), null);
    } else {
        gl.drawArrays(@intFromEnum(self.drawmode), 0, self.vertcnt);
    }
}

const Self = @This();
const Buffer = @import("Buffer.zig");
const Allocator = std.mem.Allocator;

pub const Id = gl.Uint;
pub const VertCnt = gl.Sizei;
pub const DrawMode = enum(gl.Enum) {
    triangles = gl.TRIANGLES,
    triangle_strip = gl.TRIANGLE_STRIP,
    lines = gl.LINES,
    points = gl.POINTS,
};

const gl = @import("zopengl").bindings;
const std = @import("std");
const log = @import("log");
