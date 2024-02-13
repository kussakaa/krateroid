const gl = @import("zopengl").bindings;

const Target = enum(gl.Enum) {
    array = gl.ARRAY_BUFFER,
    elements_array = gl.ELEMENT_ARRAY_BUFFER,
};

const Usage = enum(gl.Enum) {
    static_draw = gl.STATIC_DRAW,
    dynamic_draw = gl.DYNAMIC_DRAW,
};

const Self = @This();

id: gl.Uint,

pub fn init() !Self {
    var id: gl.Uint = 0;
    gl.genBuffers(1, &id);
    return .{ .id = id };
}

pub fn deinit(self: Self) void {
    gl.deleteBuffers(1, &self.id);
}

pub fn data(self: Self, target: Target, bytes: []const u8, usage: Usage) !void {
    gl.bindBuffer(@intFromEnum(target), self.id);
    gl.bufferData(
        @intFromEnum(target),
        @intCast(bytes.len),
        bytes.ptr,
        @intFromEnum(usage),
    );
}

pub fn subdata(self: Self, target: Target, offset: usize, bytes: []const u8) void {
    gl.bindBuffer(@intFromEnum(target), self.id);
    gl.bufferSubData(
        @intFromEnum(target),
        @intCast(offset),
        @intCast(bytes.len),
        bytes.ptr,
    );
}
