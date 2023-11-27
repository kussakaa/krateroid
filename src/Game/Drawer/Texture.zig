const std = @import("std");
const log = std.log.scoped(.Texture);
const c = @import("../../c.zig");

const Texture = @This();

fn glGetError() !void {
    switch (c.glGetError()) {
        0 => {},
        else => return error.GLError,
    }
}

id: u32 = 0,
size: @Vector(2, i32),
channels: i32,

pub fn init(path: []const u8) !Texture {
    var width: i32 = 0;
    var height: i32 = 0;
    var channels: i32 = 0;
    const data = c.stbi_load(path.ptr, &width, &height, &channels, 0);

    if (data == null) {
        log.err("failed image upload in path {s}", .{path});
        return error.ImageUpload;
    }

    var id: u32 = 0;

    c.glGenTextures(1, &id);
    c.glBindTexture(c.GL_TEXTURE_2D, id);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    const format = switch (channels) {
        1 => c.GL_RED,
        3 => c.GL_RGB,
        4 => c.GL_RGBA,
        else => {
            log.err("invalid channels count {}", .{channels});
            return error.ChannelsCount;
        },
    };

    c.glTexImage2D(c.GL_TEXTURE_2D, 0, @intCast(format), width, height, 0, @intCast(format), c.GL_UNSIGNED_BYTE, data);
    c.glBindTexture(c.GL_TEXTURE_2D, 0);
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
    c.glDeleteTextures(1, &self.id);
}

pub fn use(self: Texture) void {
    c.glBindTexture(c.GL_TEXTURE_2D, self.id);
}
