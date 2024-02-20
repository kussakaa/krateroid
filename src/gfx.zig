const std = @import("std");
const log = std.log.scoped(.data);

pub const Buffer = @import("gfx/Buffer.zig");
pub const Mesh = @import("gfx/Mesh.zig");
pub const Texture = @import("gfx/Texture.zig");
pub const Shader = @import("gfx/Shader.zig");
pub const Program = @import("gfx/Program.zig");
pub const Uniform = @import("gfx/Uniform.zig");

const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;
const Map = std.StringHashMapUnmanaged;

var _allocator: std.mem.Allocator = undefined;
var _buffers: Array(Buffer) = undefined;
var _meshes: Array(Mesh) = undefined;
var _textures: Map(Texture) = undefined;
var _programs: Map(Program) = undefined;

pub fn init(info: struct { allocator: Allocator = std.heap.page_allocator }) !void {
    _allocator = info.allocator;
}

pub fn deinit() void {
    for (_buffers.items) |item| item.deinit();
    _buffers.deinit(_allocator);

    for (_meshes.items) |item| item.deinit();
    _meshes.deinit(_allocator);

    var programs_iterator = _programs.iterator();
    while (programs_iterator.next()) |item| item.value_ptr.deinit();
    _programs.deinit(_allocator);

    var textures_iterator = _textures.iterator();
    while (textures_iterator.next()) |item| item.value_ptr.deinit();
    _textures.deinit(_allocator);
}

pub fn initBuffer(name: []const u8) !*Buffer {
    log.debug("init buffer {s}", .{name});
    try _buffers.append(_allocator, Buffer.init(name));
    return &_buffers.items[_buffers.items.len - 1];
}

pub fn initMesh(name: []const u8) !*Mesh {
    log.debug("init mesh {s}", .{name});
    try _meshes.append(_allocator, Mesh.init(name));
    return &_meshes.items[_meshes.items.len - 1];
}

pub fn initTexture(path: []const u8) !*Texture {
    if (_textures.getPtr(path)) |item| {
        return item;
    } else {
        const prefix = "data/texture/";

        const fullpath = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path }, 0);
        defer _allocator.free(fullpath);

        log.debug("init texture {s}", .{path});
        try _textures.put(_allocator, path, try Texture.init(fullpath));
        return _textures.getPtr(path).?;
    }
}

pub fn initProgram(path: []const u8) !Program {
    if (_programs.get(path)) |item| {
        return item;
    } else {
        const prefix = "data/shader/";

        const path_vertex = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path, "/vert.glsl" }, 0);
        defer _allocator.free(path_vertex);
        const vertex = try Shader.initFromFile(_allocator, path_vertex, .vertex);
        defer vertex.deinit();

        const path_fragment = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path, "/frag.glsl" }, 0);
        defer _allocator.free(path_fragment);
        const fragment = try Shader.initFromFile(_allocator, path_fragment, .fragment);
        defer fragment.deinit();

        log.debug("init program {s}", .{path});
        try _programs.put(_allocator, path, try Program.init(_allocator, path, .{ .vertex = vertex, .fragment = fragment }));
        return _programs.get(path).?;
    }
}

pub fn initUniform(program: Program, name: [:0]const u8) !Uniform {
    log.debug("init uniform {s} in program {s}", .{ name, program.name });
    return try Uniform.init(program, name);
}
