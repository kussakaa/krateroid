const std = @import("std");
const gl = @import("zopengl");

const log = std.log.scoped(.gfx);

const Self = @This();

id: i32,

pub fn init(program: u32, name: []const u8) !Self {
    const self = Self{ .id = @intCast(gl.getUniformLocation(program, @ptrCast(name))) };
    log.debug("init {}", .{self});
    return self;
}

// отправление значение в шейдер по идентификатору юниформы
pub fn set(self: Self, value: anytype) void {
    const id = self.id;
    switch (comptime @TypeOf(value)) {
        f32 => gl.uniform1f(id, value),
        comptime_float => gl.uniform1f(id, value),
        i32 => gl.uniform1i(id, value),
        comptime_int => gl.uniform1i(id, value),
        @Vector(3, f32) => {
            const array: [3]f32 = value;
            gl.uniform3fv(id, 1, &array);
        },
        @Vector(4, f32) => {
            const array: [4]f32 = value;
            gl.uniform4fv(id, 1, &array);
        },
        @Vector(2, i32) => {
            const array: [2]i32 = value;
            gl.uniform2iv(id, 1, &array);
        },
        @Vector(3, i32) => {
            const array: [3]i32 = value;
            gl.uniform3iv(id, 1, &array);
        },
        @Vector(4, i32) => {
            const array: [4]i32 = value;
            gl.uniform4iv(id, 1, &array);
        },
        [4]@Vector(4, f32) => {
            const array = [16]f32{
                value[0][0], value[1][0], value[2][0], value[3][0],
                value[0][1], value[1][1], value[2][1], value[3][1],
                value[0][2], value[1][2], value[2][2], value[3][2],
                value[0][3], value[1][3], value[2][3], value[3][3],
            };
            gl.uniformMatrix4fv(id, 1, gl.TRUE, &array);
        },
        else => @compileError("gfx.Program.Uniform.set() not implemented for type: " ++ @typeName(@TypeOf(value))),
    }
}
