const std = @import("std");
const gl = @import("zopengl");

const log = std.log.scoped(.gfx);
const c = @import("../c.zig");

const Texture = @This();

id: u32 = 0,
size: @Vector(2, i32),
channels: i32,

pub fn init(path: []const u8) !Texture {
    var width: i32 = 0;
    var height: i32 = 0;
    var channels: i32 = 4;
    const data = c.stbi_load(path.ptr, &width, &height, &channels, 0);

    if (data == null) {
        log.err("failed image upload in path {s}", .{path});
        return error.ImageUpload;
    }

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

    gl.texImage2D(gl.TEXTURE_2D, 0, format, width, height, 0, format, gl.UNSIGNED_BYTE, data);
    gl.bindTexture(gl.TEXTURE_2D, 0);
    c.stbi_image_free(data);

    const texture = Texture{
        .id = id,
        .size = .{ width, height },
        .channels = channels,
    };
    log.debug("init {}", .{texture});
    return texture;
}

pub fn deinit(self: Texture) void {
    log.debug("deinit {}", .{self});
    gl.deleteTextures(1, &self.id);
}

pub fn use(self: Texture) void {
    gl.bindTexture(gl.TEXTURE_2D, self.id);
}
