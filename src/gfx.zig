const std = @import("std");
const stb = @import("zstbi");
const gl = @import("zopengl").bindings;
const log = std.log.scoped(.gfx);

pub const Buffer = @import("gfx/Buffer.zig");
pub const Mesh = @import("gfx/Mesh.zig");
pub const Texture = @import("gfx/Texture.zig");
pub const Shader = @import("gfx/Shader.zig");
pub const Program = @import("gfx/Program.zig");
pub const Uniform = @import("gfx/Uniform.zig");

const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;
const Map = std.StringHashMapUnmanaged;

const GlId = gl.Uint;

var _allocator: std.mem.Allocator = undefined;
var _buffers_glid: Array(GlId) = undefined;
var _meshes_glid: Array(GlId) = undefined;
var _textures_glid: Array(GlId) = undefined;
var _programs_glid: Array(GlId) = undefined;
var _uniforms_glid: Array(gl.Int) = undefined;

pub var buffers: Array(Buffer) = undefined;
pub var meshes: Array(Mesh) = undefined;
pub var textures: Array(Texture) = undefined;
pub var programs: Array(Program) = undefined;
pub var uniforms: Array(Uniform) = undefined;

pub fn init(info: struct { allocator: Allocator }) !void {
    _allocator = info.allocator;
    stb.init(_allocator);
}

pub fn deinit() void {
    gl.deleteBuffers(@intCast(_buffers_glid.items.len), _buffers_glid.items.ptr);
    _buffers_glid.deinit(_allocator);
    buffers.deinit(_allocator);

    gl.deleteVertexArrays(@intCast(_meshes_glid.items.len), _meshes_glid.items.ptr);
    _meshes_glid.deinit(_allocator);
    meshes.deinit(_allocator);

    gl.deleteTextures(@intCast(_textures_glid.items.len), _textures_glid.items.ptr);
    _textures_glid.deinit(_allocator);
    textures.deinit(_allocator);

    for (_programs_glid.items) |item| gl.deleteProgram(item);
    _programs_glid.deinit(_allocator);
    programs.deinit(_allocator);

    stb.deinit();
}

pub fn buffer(info: struct {
    name: []const u8,
    target: Buffer.Target,
    datatype: Buffer.DataType = .f32,
    vertsize: Buffer.VertSize = 3,
    usage: Buffer.Usage = .static_draw,
}) !Buffer.Id {
    var glid: gl.Uint = 0;
    gl.genBuffers(1, &glid);
    log.debug("init buffer {s} {}", .{ info.name, glid });
    try _buffers_glid.append(_allocator, glid);
    try buffers.append(_allocator, Buffer{
        .id = buffers.items.len,
        .name = info.name,
        .target = info.target,
        .datatype = info.datatype,
        .vertsize = info.vertsize,
        .usage = info.usage,
    });
    return buffers.items.len - 1;
}

pub fn bufferData(id: Buffer.Id, bytes: []const u8) void {
    gl.bindBuffer(@intFromEnum(buffers.items[id].target), _buffers_glid.items[id]);
    gl.bufferData(
        @intFromEnum(buffers.items[id].target),
        @intCast(bytes.len),
        bytes.ptr,
        @intFromEnum(buffers.items[id].usage),
    );
}

pub fn BufferSubData(id: Buffer.Id, offset: usize, bytes: []const u8) void {
    gl.bindBuffer(@intFromEnum(buffers.items[id].target), _buffers_glid.items[id]);
    gl.bufferSubData(
        @intFromEnum(buffers.items[id].target),
        @intCast(offset),
        @intCast(bytes.len),
        bytes.ptr,
    );
}

pub fn mesh(info: struct {
    name: []const u8,
    buffers: []const Buffer.Id,
    vertcnt: Mesh.VertCnt,
    drawmode: Mesh.DrawMode,
    ebo: ?Buffer.Id = null,
}) !Mesh.Id {
    var glid: GlId = 0;
    gl.genVertexArrays(1, &glid);
    gl.bindVertexArray(glid);
    for (info.buffers, 0..) |b, i| {
        gl.bindBuffer(gl.ARRAY_BUFFER, _buffers_glid.items[b]);
        gl.enableVertexAttribArray(@intCast(i));
        gl.vertexAttribPointer(@intCast(i), buffers.items[b].vertsize, @intFromEnum(buffers.items[b].datatype), gl.FALSE, 0, null);
    }
    log.debug("init mesh {s} {}", .{ info.name, glid });
    try _meshes_glid.append(_allocator, glid);
    try meshes.append(_allocator, Mesh{
        .id = meshes.items.len,
        .name = info.name,
        .vertcnt = info.vertcnt,
        .drawmode = info.drawmode,
        .ebo = info.ebo,
    });
    return meshes.items.len - 1;
}

pub fn meshDraw(id: Mesh.Id) void {
    const m = meshes.items[id];
    const glid = _meshes_glid.items[id];
    gl.bindVertexArray(glid);
    if (m.ebo) |ebo| {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _buffers_glid.items[ebo]);
        gl.drawElements(@intFromEnum(m.drawmode), m.vertcnt, @intFromEnum(buffers.items[ebo].datatype), null);
    } else {
        gl.drawArrays(@intFromEnum(m.drawmode), 0, m.vertcnt);
    }
}

pub fn texture(name: []const u8) !Texture.Id {
    const prefix = "data/texture/";
    const full_path = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, name }, 0);
    defer _allocator.free(full_path);

    var image = try stb.Image.loadFromFile(full_path, 4);
    defer image.deinit();

    var glid: GlId = 0;

    gl.genTextures(1, &glid);
    gl.bindTexture(gl.TEXTURE_2D, glid);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    const format: Texture.Format = switch (image.num_components) {
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
    try _textures_glid.append(_allocator, glid);
    try textures.append(_allocator, Texture{
        .id = textures.items.len,
        .name = name,
        .size = .{ image.width, image.height },
        .format = format,
    });
    return textures.items.len - 1;
}

pub fn textureUse(id: Texture.Id) void {
    gl.bindTexture(gl.TEXTURE_2D, _textures_glid.items[id]);
}

pub fn program(name: []const u8) !Program.Id {
    const glid = gl.createProgram();

    const prefix = "data/shader/";

    const vert_path = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, name, "/vert.glsl" }, 0);
    defer _allocator.free(vert_path);
    const vert = try shader(vert_path, .vert);
    defer gl.deleteShader(vert);
    gl.attachShader(glid, vert);
    defer gl.detachShader(glid, vert);

    const frag_path = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, name, "/frag.glsl" }, 0);
    defer _allocator.free(frag_path);
    const frag = try shader(frag_path, .frag);
    defer gl.deleteShader(frag);
    gl.attachShader(glid, frag);
    defer gl.detachShader(glid, frag);

    gl.linkProgram(glid);

    // error catching
    var succes: gl.Int = 1;
    gl.getProgramiv(glid, gl.LINK_STATUS, &succes);
    if (succes <= 0) {
        var info_log_len: gl.Int = 0;
        gl.getProgramiv(glid, gl.INFO_LOG_LENGTH, &info_log_len);
        const info_log = try _allocator.alloc(u8, @intCast(info_log_len));
        defer _allocator.free(info_log);
        gl.getProgramInfoLog(glid, info_log_len, null, info_log.ptr);
        log.err("program {} failed linkage: {s}", .{ glid, info_log });
        return error.ShaderProgramLinkage;
    }

    log.debug("init program {s}", .{name});
    try _programs_glid.append(_allocator, glid);
    try programs.append(_allocator, Program{ .id = programs.items.len, .name = name });
    return programs.items.len - 1;
}

pub fn programUse(id: Program.Id) void {
    gl.useProgram(_programs_glid.items[id]);
}

fn shader(
    path: []const u8,
    shadertype: Shader.Type,
) !GlId {
    const data = try std.fs.cwd().readFileAlloc(_allocator, path, 100_000_000);
    defer _allocator.free(data);
    const glid = gl.createShader(@intFromEnum(shadertype));
    gl.shaderSource(glid, 1, &data.ptr, @ptrCast(&.{@as(gl.Int, @intCast(data.len))}));
    gl.compileShader(glid);

    // error catching
    var succes: gl.Int = 1;
    gl.getShaderiv(glid, gl.COMPILE_STATUS, &succes);
    if (succes == 0) {
        var info_log_len: gl.Int = 0;
        gl.getShaderiv(glid, gl.INFO_LOG_LENGTH, &info_log_len);
        const info_log = try _allocator.alloc(u8, @intCast(info_log_len));
        defer _allocator.free(info_log);
        gl.getShaderInfoLog(glid, info_log_len, null, info_log.ptr);
        log.err("shader {} failed compilation: {s}\n", .{ glid, info_log });
        return error.ShaderCompilation;
    }

    return glid;
}

pub fn uniform(id: Program.Id, name: []const u8) !Uniform.Id {
    const glid = gl.getUniformLocation(_programs_glid.items[id], name.ptr);
    try _uniforms_glid.append(_allocator, glid);
    try uniforms.append(_allocator, Uniform{ .id = uniforms.items.len, .name = name });
    log.debug("init uniform {s} in program {s}", .{ name, programs.items[id].name });
    return uniforms.items.len - 1;
}

pub fn uniformSet(id: Uniform.Id, value: anytype) void {
    const glid = _uniforms_glid.items[id];
    switch (comptime @TypeOf(value)) {
        f32 => gl.uniform1f(glid, value),
        comptime_float => gl.uniform1f(glid, value),
        @Vector(2, f32) => {
            const array: [2]f32 = value;
            gl.uniform2iv(glid, 1, &array);
        },
        @Vector(3, f32) => {
            const array: [3]f32 = value;
            gl.uniform3fv(glid, 1, &array);
        },
        @Vector(4, f32) => {
            const array: [4]f32 = value;
            gl.uniform4fv(glid, 1, &array);
        },
        [4]@Vector(4, f32) => {
            const array = [16]f32{
                value[0][0], value[0][1], value[0][2], value[0][3],
                value[1][0], value[1][1], value[1][2], value[1][3],
                value[2][0], value[2][1], value[2][2], value[2][3],
                value[3][0], value[3][1], value[3][2], value[3][3],
            };
            gl.uniformMatrix4fv(glid, 1, gl.FALSE, &array);
        },
        i32 => gl.uniform1i(glid, value),
        comptime_int => gl.uniform1i(glid, value),
        @Vector(2, i32) => {
            const array: [2]i32 = value;
            gl.uniform2iv(glid, 1, &array);
        },
        @Vector(3, i32) => {
            const array: [3]i32 = value;
            gl.uniform3iv(glid, 1, &array);
        },
        @Vector(4, i32) => {
            const array: [4]i32 = value;
            gl.uniform4iv(glid, 1, &array);
        },
        u32 => gl.uniform1ui(id, value),
        @Vector(2, u32) => {
            const array: [2]u32 = value;
            gl.uniform2uiv(glid, 1, &array);
        },
        @Vector(3, u32) => {
            const array: [3]u32 = value;
            gl.uniform3uiv(glid, 1, &array);
        },
        else => @compileError("gfx.Uniform.set() not implemented for type: " ++ @typeName(@TypeOf(value))),
    }
}
