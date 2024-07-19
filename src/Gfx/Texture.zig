id: Id,
name: []const u8,
size: Size,
format: Format,

pub fn init(
    allocator: Allocator,
    config: struct {
        name: []const u8,
        min_filter: MinFilter = .nearest,
        mag_filter: MagFilter = .nearest,
        wrap_s: Wrap = .repeat,
        wrap_t: Wrap = .repeat,
        wrap_r: Wrap = .repeat,
        mipmap: bool = false,
    },
) !Self {
    const name = config.name;
    const prefix = "data/texture/";
    const full_path = try std.mem.concatWithSentinel(allocator, u8, &.{ prefix, name }, 0);
    defer allocator.free(full_path);

    var image = try stb.Image.loadFromFile(full_path, 4);
    defer image.deinit();

    var id: Id = undefined;

    gl.genTextures(1, &id);
    gl.bindTexture(gl.TEXTURE_2D, id);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, @intFromEnum(config.min_filter));
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, @intFromEnum(config.mag_filter));
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, @intFromEnum(config.wrap_s));
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, @intFromEnum(config.wrap_t));
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_R, @intFromEnum(config.wrap_r));

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

    if (config.mipmap) {
        gl.generateMipmap(gl.TEXTURE_2D);
    }

    log.succes(.init, "GFX Texture name:{s} id:{}", .{ name, id });
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

pub fn bind(self: Self, binding: gl.Enum) void {
    gl.activeTexture(gl.TEXTURE0 + binding);
    gl.bindTexture(gl.TEXTURE_2D, self.id);
}

const Self = @This();
const Allocator = std.mem.Allocator;

pub const Id = gl.Uint;
pub const Size = @Vector(2, u32);

pub const Format = enum(gl.Enum) {
    red = gl.RED,
    rgb = gl.RGB,
    rgba = gl.RGBA,
};

pub const MinFilter = enum(gl.Int) {
    nearest = gl.NEAREST,
    linear = gl.LINEAR,
    nearest_mipmap_nearest = gl.NEAREST_MIPMAP_NEAREST,
    linear_mipmap_nearest = gl.LINEAR_MIPMAP_NEAREST,
    nearest_mipmap_linear = gl.NEAREST_MIPMAP_LINEAR,
    linear_mipmap_linear = gl.LINEAR_MIPMAP_LINEAR,
};

pub const MagFilter = enum(gl.Int) {
    nearest = gl.NEAREST,
    linear = gl.LINEAR,
};

pub const Wrap = enum(gl.Int) {
    repeat = gl.REPEAT,
};

const stb = @import("zstbi");
const gl = @import("zopengl").bindings;

const std = @import("std");
const log = @import("log");
