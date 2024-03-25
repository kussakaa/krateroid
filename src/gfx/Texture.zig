const std = @import("std");
const log = std.log.scoped(.gfx);

const Allocator = std.mem.Allocator;

const stb = @import("zstbi");
const gl = @import("zopengl").bindings;

pub const Id = gl.Uint;
pub const Size = @Vector(2, u32);
pub const Format = enum(gl.Enum) {
    red = gl.RED,
    rgb = gl.RGB,
    rgba = gl.RGBA,
};
const Self = @This();

id: Id,
name: []const u8,
size: Size,
format: Format,

pub fn init(allocator: Allocator, name: []const u8) !Self {
    const prefix = "data/texture/";
    const full_path = try std.mem.concatWithSentinel(allocator, u8, &.{ prefix, name }, 0);
    defer allocator.free(full_path);

    var image = try stb.Image.loadFromFile(full_path, 4);
    defer image.deinit();

    var id: Id = undefined;

    gl.genTextures(1, &id);
    gl.bindTexture(gl.TEXTURE_2D, id);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    const format: Format = switch (image.num_components) {
        1 => .red,
        3 => .rgb,
        4 => .rgba,
        else => return error.ImageUnknownFormat,
    };

    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        @intFromEnum(format),
        @intCast(image.width),
        @intCast(image.height),
        0,
        @intFromEnum(format),
        gl.UNSIGNED_BYTE,
        image.data.ptr,
    );

    log.debug("init texture {s}", .{name});
    return .{
        .id = id,
        .name = name,
        .size = .{ image.width, image.height },
        .format = format,
    };
}

pub fn deinit(self: Self) void {
    gl.deleteTextures(1, &self.id);
}

pub fn use(self: Self) void {
    gl.bindTexture(gl.TEXTURE_2D, self.id);
}
