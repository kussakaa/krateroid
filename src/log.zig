pub fn succes(comptime format: []const u8, args: anytype) void {
    if (builtin.mode == .Debug) {
        const writer = std.io.getStdErr().writer();
        const prefix = comptime Color(null).bold() ++ Color(.fg).bit(2) ++ "[SUCCES]:" ++ Color(null).reset();
        writer.print(prefix ++ format ++ "\n", args) catch return;
    }
}

pub fn failed(comptime format: []const u8, args: anytype) void {
    if (builtin.mode == .Debug) {
        const writer = std.io.getStdErr().writer();
        const prefix = comptime Color(null).bold() ++ Color(.fg).bit(1) ++ "[FAILED]:" ++ Color(null).reset();
        writer.print(prefix ++ format ++ "\n", args) catch return;
    }
}

const Color = @import("terminal").Color;
const std = @import("std");
const builtin = @import("builtin");
