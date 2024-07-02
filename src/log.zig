pub fn succes(comptime t: Type, comptime format: []const u8, args: anytype) void {
    if (builtin.mode == .Debug) {
        const writer = std.io.getStdErr().writer();
        const prefix = comptime Color(null).bold() ++ Color(.fg).bit(2) ++ "[SUCCES]" ++ Color(null).reset() ++ ":" ++ t.str() ++ ":";
        writer.print(prefix ++ format ++ "\n", args) catch return;
    }
}

pub fn failed(comptime t: Type, comptime format: []const u8, args: anytype) void {
    if (builtin.mode == .Debug) {
        const writer = std.io.getStdErr().writer();
        const prefix = comptime Color(null).bold() ++ Color(.fg).bit(1) ++ "[FAILED]" ++ Color(null).reset() ++ ":" ++ t.str() ++ ":";
        writer.print(prefix ++ format ++ "\n", args) catch return;
    }
}

const Type = enum {
    init,
    loop,

    fn str(comptime self: @This()) []const u8 {
        return switch (self) {
            .init => Color(.fg).bit(5) ++ "[INIT]" ++ Color(null).reset(),
            .loop => Color(.fg).bit(5) ++ "[LOOP]" ++ Color(null).reset(),
        };
    }
};

const Color = @import("terminal").Color;
const std = @import("std");
const builtin = @import("builtin");
