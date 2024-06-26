const std = @import("std");
const log = std.log.scoped(.gfx);

const Program = @import("Program.zig");
const Texture = @import("Texture.zig");

const gl = @import("zopengl").bindings;

pub const Id = gl.Int;
const Self = @This();

id: Id,
name: []const u8,

pub fn init(program: Program, name: []const u8) !Self {
    const id = gl.getUniformLocation(program.id, name.ptr);
    log.debug("init uniform {s} in program {s}", .{ name, program.name });
    return .{ .id = id, .name = name };
}

pub fn set(self: Self, value: anytype) void {
    switch (comptime @TypeOf(value)) {
        f32 => gl.uniform1f(self.id, value),
        comptime_float => gl.uniform1f(self.id, value),
        @Vector(2, f32) => {
            const array: [2]f32 = value;
            gl.uniform2iv(self.id, 1, &array);
        },
        @Vector(3, f32) => {
            const array: [3]f32 = value;
            gl.uniform3fv(self.id, 1, &array);
        },
        @Vector(4, f32) => {
            const array: [4]f32 = value;
            gl.uniform4fv(self.id, 1, &array);
        },
        [4]@Vector(4, f32) => {
            const array = [16]f32{
                value[0][0], value[0][1], value[0][2], value[0][3],
                value[1][0], value[1][1], value[1][2], value[1][3],
                value[2][0], value[2][1], value[2][2], value[2][3],
                value[3][0], value[3][1], value[3][2], value[3][3],
            };
            gl.uniformMatrix4fv(self.id, 1, gl.FALSE, &array);
        },
        i32 => gl.uniform1i(self.id, value),
        comptime_int => gl.uniform1i(self.id, value),
        @Vector(2, i32) => {
            const array: [2]i32 = value;
            gl.uniform2iv(self.id, 1, &array);
        },
        @Vector(3, i32) => {
            const array: [3]i32 = value;
            gl.uniform3iv(self.id, 1, &array);
        },
        @Vector(4, i32) => {
            const array: [4]i32 = value;
            gl.uniform4iv(self.id, 1, &array);
        },
        u32 => gl.uniform1ui(self.id, value),
        @Vector(2, u32) => {
            const array: [2]u32 = value;
            gl.uniform2uiv(self.id, 1, &array);
        },
        @Vector(3, u32) => {
            const array: [3]u32 = value;
            gl.uniform3uiv(self.id, 1, &array);
        },
        Texture => {
            gl.uniform1i(self.id, value.id);
        },
        else => @compileError("gfx.Uniform.set() not implemented for type: " ++ @typeName(@TypeOf(value))),
    }
}
