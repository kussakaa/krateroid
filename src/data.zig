const std = @import("std");
const log = std.log.scoped(.data);
const gfx = @import("gfx.zig");

const Allocator = std.mem.Allocator;
const Map = std.StringHashMapUnmanaged;

var _allocator: std.mem.Allocator = undefined;
var _programs: Map(gfx.Program) = undefined;
var _textures: Map(gfx.Texture) = undefined;

pub fn init(info: struct { allocator: Allocator = std.heap.page_allocator }) !void {
    _allocator = info.allocator;
}

pub fn deinit() void {
    var pi = _programs.iterator();
    while (pi.next()) |item| item.value_ptr.deinit();
    _programs.deinit(_allocator);

    var ti = _textures.iterator();
    while (ti.next()) |item| item.value_ptr.deinit();
    _textures.deinit(_allocator);
}

pub fn program(path: []const u8) !gfx.Program {
    if (_programs.get(path)) |p| {
        return p;
    } else {
        const prefix = "data/shader/";

        const path_vertex = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path, "/vertex.glsl" }, 0);
        defer _allocator.free(path_vertex);
        const vertex = try gfx.Shader.initFromFile(_allocator, path_vertex, .vertex);
        defer vertex.deinit();

        const path_fragment = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path, "/fragment.glsl" }, 0);
        defer _allocator.free(path_fragment);
        const fragment = try gfx.Shader.initFromFile(_allocator, path_fragment, .fragment);
        defer fragment.deinit();

        try _programs.put(_allocator, path, try gfx.Program.init(_allocator, path, &.{ vertex, fragment }));
        log.debug("init program {s}", .{path});

        return _programs.get(path).?;
    }
}

pub fn uniform(p: gfx.Program, name: [:0]const u8) !gfx.Uniform {
    const u = try gfx.Uniform.init(p, name);
    log.debug("init uniform {s} in program {s}", .{ name, p.name });

    return u;
}

pub fn texture(path: []const u8) !gfx.Texture {
    if (_textures.get(path)) |t| {
        return t;
    } else {
        const prefix = "data/texture/";

        const fullpath = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path }, 0);
        defer _allocator.free(fullpath);

        try _textures.put(_allocator, path, try gfx.Texture.init(fullpath));
        log.debug("init texture {s}", .{path});

        return _textures.get(path).?;
    }
}
