map: *Map,
allocator: Allocator,

pub const Config = struct {
    map: Map.Config = .{},
};

pub fn init(allocator: Allocator, config: Config) !Self {
    const map = try allocator.create(Map);
    map.* = try Map.init(allocator, config.map);

    log.succes(.init, "WORLD", .{});

    return .{
        .map = map,
        .allocator = allocator,
    };
}

pub fn deinit(self: Self) void {
    self.map.deinit();
    self.allocator.destroy(self.map);
}

pub fn update(self: Self) bool {
    _ = self;
    return true;
}

pub const Map = @import("World/Map.zig");

const Self = @This();
const Allocator = std.mem.Allocator;

const std = @import("std");
const log = @import("log");
const assert = std.debug.assert;
const znoise = @import("znoise");
const Noise = znoise.FnlGenerator;
