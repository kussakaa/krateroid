const std = @import("std");
const log = std.log.scoped(.gfx);

const c = @import("../../c.zig");

const Self = @This();

id: i32,

pub fn init(program: u32, name: []const u8) !Self {
    const self = Self{ .id = @intCast(c.glGetUniformLocation(program, @ptrCast(name))) };
    log.debug("init {}", .{self});
    return self;
}

// отправление значение в шейдер по идентификатору юниформы
pub fn set(self: Self, value: anytype) void {
    const id = self.id;
    switch (comptime @TypeOf(value)) {
        f32 => c.glUniform1f(id, value),
        comptime_float => c.glUniform1f(id, value),
        i32 => c.glUniform1i(id, value),
        comptime_int => c.glUniform1i(id, value),
        @Vector(3, f32) => {
            const array: [3]f32 = value;
            c.glUniform3fv(id, 1, &array);
        },
        @Vector(4, f32) => {
            const array: [4]f32 = value;
            c.glUniform4fv(id, 1, &array);
        },
        @Vector(2, i32) => {
            const array: [2]i32 = value;
            c.glUniform2iv(id, 1, &array);
        },
        @Vector(3, i32) => {
            const array: [3]i32 = value;
            c.glUniform3iv(id, 1, &array);
        },
        @Vector(4, i32) => {
            const array: [4]i32 = value;
            c.glUniform4iv(id, 1, &array);
        },
        [4]@Vector(4, f32) => {
            const array = [16]f32{
                value[0][0], value[1][0], value[2][0], value[3][0],
                value[0][1], value[1][1], value[2][1], value[3][1],
                value[0][2], value[1][2], value[2][2], value[3][2],
                value[0][3], value[1][3], value[2][3], value[3][3],
            };
            c.glUniformMatrix4fv(id, 1, c.GL_FALSE, &array);
        },
        else => @compileError("gfx.Program.Uniform.set() not implemented for type: " ++ @typeName(@TypeOf(value))),
    }
}