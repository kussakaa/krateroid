const std = @import("std");
const log = std.log.scoped(.data);

pub usingnamespace @import("gfx/wrapper.zig");
pub const Buffer = @import("gfx/Buffer.zig");
pub const Texture = @import("gfx/Texture.zig");
pub const Shader = @import("gfx/Shader.zig");
pub const Program = @import("gfx/Program.zig");
pub const Uniform = @import("gfx/Uniform.zig");
pub const Vbo = @import("gfx/Vbo.zig");
pub const Vao = @import("gfx/Vao.zig");
pub const Ebo = @import("gfx/Ebo.zig");

const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;
const Map = std.StringHashMapUnmanaged;

var _allocator: std.mem.Allocator = undefined;
var _buffers: Array(Buffer) = undefined;
var _textures: Map(Texture) = undefined;
var _programs: Map(Program) = undefined;

pub fn init(info: struct { allocator: Allocator = std.heap.page_allocator }) !void {
    _allocator = info.allocator;
    _buffers = try Array(Buffer).initCapacity(_allocator, 256);
}

pub fn deinit() void {
    var pi = _programs.iterator();
    while (pi.next()) |item| item.value_ptr.deinit();
    _programs.deinit(_allocator);

    var ti = _textures.iterator();
    while (ti.next()) |item| item.value_ptr.deinit();
    _textures.deinit(_allocator);
}

//pub fn buffer() !Buffer {
//    try _buffers.append(_allocator, try Buffer.init());
//    return _buffers.items[_buffers.len - 1];
//}

pub fn addTexture(path: []const u8) !Texture {
    const prefix = "data/texture/";

    const fullpath = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path }, 0);
    defer _allocator.free(fullpath);

    try _textures.put(_allocator, path, try Texture.init(fullpath));
    log.debug("init texture {s}", .{path});

    return _textures.get(path).?;
}

pub fn getTexture(path: []const u8) !Texture {
    if (_textures.get(path)) |program| {
        return program;
    } else {
        log.err("texture {s} isnt init", .{path});
        return error.UndefinedTexture;
    }
}

pub fn addProgram(path: []const u8) !Program {
    const prefix = "data/shader/";

    const path_vertex = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path, "/vertex.glsl" }, 0);
    defer _allocator.free(path_vertex);
    const vertex = try Shader.initFromFile(_allocator, path_vertex, .vertex);
    defer vertex.deinit();

    const path_fragment = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path, "/fragment.glsl" }, 0);
    defer _allocator.free(path_fragment);
    const fragment = try Shader.initFromFile(_allocator, path_fragment, .fragment);
    defer fragment.deinit();

    try _programs.put(_allocator, path, try Program.init(
        _allocator,
        path,
        .{ .vertex = vertex, .fragment = fragment },
    ));
    log.debug("init program {s}", .{path});

    return _programs.get(path).?;
}

pub fn getProgram(path: []const u8) !Program {
    if (_programs.get(path)) |program| {
        return program;
    } else {
        log.err("program {s} isnt init", .{path});
        return error.UndefinedShaderProgram;
    }
}

pub fn getUniform(p: Program, name: [:0]const u8) !Uniform {
    const u = try Uniform.init(p, name);
    log.debug("init uniform {s} in program {s}", .{ name, p.name });
    return u;
}
