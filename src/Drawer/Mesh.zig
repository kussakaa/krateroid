const std = @import("std");
const log = std.log.scoped(.GameDrawerMesh);
const c = @import("../c.zig");

pub const Verts = @import("Mesh/Verts.zig");
pub const Elems = @import("Mesh/Elems.zig");

const Mesh = @This();

verts: Verts,
elems: Elems,

const Usage = enum(u32) {
    static = c.GL_STATIC_DRAW,
    dynamic = c.GL_DYNAMIC_DRAW,
};

const Mode = enum(u32) {
    triangles = c.GL_TRIANGLES,
    lines = c.GL_LINES,
};

pub fn draw(self: Mesh) !void {
    try self.elems.draw(self.verts);
}
