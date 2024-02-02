const std = @import("std");
const log = std.log.scoped(.data);
const gfx = @import("gfx.zig");

const Allocator = std.mem.Allocator;

var _allocator: std.mem.Allocator = undefined;
var _textures: std.StringHashMapUnmanaged(gfx.Texture) = undefined;

pub fn init(info: struct { allocator: Allocator = std.heap.page_allocator }) !void {
    _allocator = info.allocator;
}

pub fn deinit() void {
    var i = _textures.iterator();
    while (i.next()) |item| {
        item.value_ptr.deinit();
    }
    _textures.deinit(_allocator);
}

//pub fn program(name:) !gfx.Program {}

pub fn uniform(program: gfx.Program, name: [:0]const u8) !gfx.Uniform {
    const u = try gfx.Uniform.init(program, name);
    log.debug("init uniform {s} in program {}", .{ name, program.id });
    return u;
}

pub fn texture(path: [:0]const u8) !gfx.Texture {
    if (_textures.get(path)) |t| {
        return t;
    } else {
        const prefix = "data/texture/";
        const fullpath = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path }, 0);
        try _textures.put(_allocator, path, try gfx.Texture.init(fullpath));
        _allocator.free(fullpath);
        log.debug("init texture {s}", .{path});
        return _textures.get(path).?;
    }
}
