const std = @import("std");
const gl = @import("zopengl").bindings;
const stb = @import("zstbi");

const log = std.log.scoped(.gfx);

const Texture = @This();

id: u32 = 0,
size: @Vector(2, u32),
channels: u32,

pub fn init(path: [:0]const u8) !Texture {
    var image = try stb.Image.loadFromFile(path, 4);
    defer image.deinit();

    const width = image.width;
    const height = image.height;
    const channels = image.num_components;

    var id: u32 = 0;

    gl.genTextures(1, &id);
    gl.bindTexture(gl.TEXTURE_2D, id);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    const format: gl.Enum = switch (channels) {
        1 => gl.RED,
        3 => gl.RGB,
        4 => gl.RGBA,
        //else => {
        //    log.err("Texture not support {} channels", .{channels});
        //    return error.ChannelsCount;
        //},
        else => 0,
    };

    gl.texImage2D(gl.TEXTURE_2D, 0, format, @intCast(width), @intCast(height), 0, format, gl.UNSIGNED_BYTE, @as(*const anyopaque, &image.data[0]));
    gl.bindTexture(gl.TEXTURE_2D, 0);

    const texture = Texture{
        .id = id,
        .size = .{ width, height },
        .channels = channels,
    };
    //log.debug("init {}", .{texture});
    return texture;
}

pub fn deinit(self: Texture) void {
    //log.debug("deinit {}", .{self});
    gl.deleteTextures(1, &self.id);
}

pub fn use(self: Texture) void {
    gl.bindTexture(gl.TEXTURE_2D, self.id);
}
