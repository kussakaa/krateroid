const gl = @import("zopengl").bindings;

const Texture = @This();

const Size = @Vector(2, u32);

id: u32 = 0,
size: Size,
channels: u32,

pub fn init(data: []const u8, size: Size, channels: u32) !Texture {
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
        else => return error.ChannelsCount,
    };

    gl.texImage2D(gl.TEXTURE_2D, 0, format, @intCast(size[0]), @intCast(size[1]), 0, format, gl.UNSIGNED_BYTE, data.ptr);
    gl.bindTexture(gl.TEXTURE_2D, 0);

    const texture = Texture{
        .id = id,
        .size = size,
        .channels = channels,
    };
    return texture;
}

pub fn deinit(self: Texture) void {
    gl.deleteTextures(1, &self.id);
}

pub fn use(self: Texture) void {
    gl.bindTexture(gl.TEXTURE_2D, self.id);
}
