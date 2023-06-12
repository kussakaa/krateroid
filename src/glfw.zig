const c = @import("c.zig");
const std = @import("std");
const print = std.debug.print;
const panic = std.debug.panic;
const I32x2 = @import("linmath.zig").I32x2;

pub fn init() !void {
    if (c.glfwInit() == 0) {
        c.glfwTerminate();
        panic("[GLFW]:Инициализация завершилась ошибкой!\n", .{});
    } else {
        print("[GLFW]:Инициализация завершилась успешно\n", .{});
    }
}

pub fn terminate() void {
    c.glfwTerminate();
}

pub const Window = struct {
    handle: ?*c.GLFWwindow,
    title: [*c]const u8,

    pub fn create(width: i32, height: i32, title: [*c]const u8) !Window {
        c.glfwWindowHint(c.GLFW_RESIZABLE, c.GLFW_TRUE);
        c.glfwWindowHint(c.GLFW_DOUBLEBUFFER, c.GLFW_TRUE);
        c.glfwWindowHint(c.GLFW_DEPTH_BITS, 24);
        c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_OPENGL_API);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
        c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GLFW_TRUE);
        c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
        const handle = c.glfwCreateWindow(@intCast(c_int, width), @intCast(c_int, height), title, null, null);
        if (handle == null) {
            terminate();
            panic("[GLFW]:[ОКНО]:Создание завершилось ошибкой!\n", .{});
        }
        c.glfwMakeContextCurrent(handle);
        if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.glfwGetProcAddress)) == 0) {
            terminate();
            panic("[GLFW]:[КОНТЕКСТ GL]:Инициализация завершилась ошибкой!\n", .{});
        }
        c.glViewport(0, 0, 800, 600);
        c.glfwSwapInterval(0);

        _ = c.glfwSetWindowSizeCallback(handle, window_size_callback);
        _ = c.glfwSetKeyCallback(handle, key_callback);
        _ = c.glfwSetMouseButtonCallback(handle, button_callback);
        _ = c.glfwSetCursorPosCallback(handle, pos_callback);

        print("[GLFW]:[ОКНО]:[Название:{s}|Ширина:{}|Высота:{}]:Создание завершилось успешно\n", .{ title, width, height });
        return Window{ .handle = handle, .title = title };
    }

    pub fn swapBuffers(self: Window) void {
        c.glfwSwapBuffers(self.handle);
    }

    pub fn shouldClose(self: Window) bool {
        return c.glfwWindowShouldClose(self.handle) != 0;
    }

    pub fn getSize(self: Window) struct {
        x: i32,
        y: i32,
    } {
        var x: c_int = 0;
        var y: c_int = 0;
        c.glfwGetWindowSize(self.handle, &x, &y);
        return .{
            .x = @intCast(i32, x),
            .y = @intCast(i32, y),
        };
    }

    pub fn destroy(self: Window) void {
        print("[GLFW]:[ОКНО]:[Название:{s}|Ширина:{}|Высота:{}]:Уничтожено\n", .{ self.title, self.getSize().x, self.getSize().y });
        c.glfwDestroyWindow(self.handle);
    }
};

var keys: [349]bool = [_]bool{false} ** 349;
var buttons: [8]bool = [_]bool{false} ** 8;
const cursor = struct {
    var pos = I32x2{ 0, 0 };
};

var frames: [357]u32 = [_]u32{0} ** 357;
var current: u32 = 0;

pub fn isPressed(keycode: i32) bool {
    if (keycode < 0 or keycode >= keys.len) return false;
    return keys[@intCast(usize, keycode)];
}

pub fn isJustPressed(keycode: i32) bool {
    if (keycode < 0 or keycode >= keys.len) return false;
    return keys[@intCast(usize, keycode)] and (frames[@intCast(usize, keycode)] == current);
}

pub fn isClicked(button: i32) bool {
    if (button < 0 or button >= buttons.len) return false;
    return buttons[@intCast(usize, button)];
}

pub fn isJustClicked(button: i32) bool {
    if (button < 0 or button >= buttons.len) return false;
    return buttons[@intCast(usize, button)] and (frames[keys.len + @intCast(usize, button)] == current);
}

pub fn cursorPos() I32x2 {
    return cursor.pos;
}

pub fn pollEvents() void {
    current += 1;
    c.glfwPollEvents();
}

fn key_callback(handle: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mode: c_int) callconv(.C) void {
    _ = handle;
    _ = scancode;
    _ = mode;
    if (action == c.GLFW_PRESS) {
        keys[@intCast(usize, key)] = true;
        frames[@intCast(usize, key)] = current;
    }
    if (action == c.GLFW_RELEASE) {
        keys[@intCast(usize, key)] = false;
        frames[@intCast(usize, key)] = current;
    }
}

fn button_callback(handle: ?*c.GLFWwindow, button: c_int, action: c_int, mode: c_int) callconv(.C) void {
    _ = handle;
    _ = mode;
    if (action == c.GLFW_PRESS) {
        buttons[@intCast(usize, button)] = true;
        frames[keys.len + @intCast(usize, button)] = current;
    } else if (action == c.GLFW_RELEASE) {
        buttons[@intCast(usize, button)] = false;
        frames[keys.len + @intCast(usize, button)] = current;
    }
}

fn pos_callback(handle: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    var vpheight: i32 = 0;
    c.glfwGetWindowSize(handle, null, &vpheight);
    cursor.pos = I32x2{ @floatToInt(i32, x), vpheight - @floatToInt(i32, y) };
}

fn window_size_callback(handle: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = handle;
    c.glViewport(0, 0, width, height);
}
