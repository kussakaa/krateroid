const std = @import("std");
const stb = @import("zstbi");
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

pub fn init(info: struct { allocator: Allocator }) !void {
    _allocator = info.allocator;
    stb.init(_allocator);
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

    stb.deinit();
}

pub fn buffer(name: []const u8) !*Buffer {
    log.debug("init buffer {s}", .{name});
    try _buffers.append(_allocator, Buffer.init(name));
    return &_buffers.items[_buffers.items.len - 1];
}

pub fn mesh(name: []const u8) !*Mesh {
    log.debug("init mesh {s}", .{name});
    try _meshes.append(_allocator, Mesh.init(name));
    return &_meshes.items[_meshes.items.len - 1];
}

pub fn texture(path: []const u8) !*Texture {
    if (_textures.getPtr(path)) |item| return item;

    const prefix = "data/texture/";
    const full_path = try std.mem.concatWithSentinel(_allocator, u8, &.{ prefix, path }, 0);
    defer _allocator.free(full_path);

    var image = try stb.Image.loadFromFile(full_path, 4);
    defer image.deinit();

    log.debug("init texture {s}", .{path});
    try _textures.put(_allocator, path, try Texture.init(image.data, .{ image.width, image.height }, image.num_components));
    return _textures.getPtr(path).?;
}

pub fn program(name: []const u8) !Program {
    if (_programs.get(name)) |item| return item;

    const full_path = try std.fs.cwd().openDir("data/shader/", .{});

    const vert_path = try std.mem.concatWithSentinel(_allocator, u8, &.{ name, "/vert.glsl" }, 0);
    defer _allocator.free(vert_path);
    const vert_data = try full_path.readFileAlloc(_allocator, vert_path, 100_000_000);
    defer _allocator.free(vert_data);
    const vert = try Shader.init(_allocator, vert_data, .vert);
    defer vert.deinit();

    const frag_path = try std.mem.concatWithSentinel(_allocator, u8, &.{ name, "/frag.glsl" }, 0);
    defer _allocator.free(frag_path);
    const frag_data = try full_path.readFileAlloc(_allocator, frag_path, 100_000_000);
    defer _allocator.free(frag_data);
    const frag = try Shader.init(_allocator, frag_data, .frag);
    defer frag.deinit();

    log.debug("init program {s}", .{name});
    try _programs.put(_allocator, name, try Program.init(_allocator, name, .{ .vert = vert, .frag = frag }));
    return _programs.get(name).?;
}

pub fn uniform(p: Program, name: [:0]const u8) !Uniform {
    log.debug("init uniform {s} in program {s}", .{ name, p.name });
    return try Uniform.init(p, name);
}
