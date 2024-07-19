map: Map,

pub const Config = struct {
    map: Map.Config = .{},
};

pub fn init(allocator: Allocator, config: Config) !Self {
    const self = Self{
        .map = try Map.init(allocator, config.map),
    };

    log.succes(.init, "WORLD System", .{});

    return self;
}

pub fn deinit(self: Self) void {
    self.map.deinit();
}

pub fn update(self: *Self) bool {
    self.map.update();
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
