const c = @import("c.zig");
const std = @import("std");
const print = std.debug.print;
const panic = std.debug.panic;

pub fn init() !void {
    if (c.glfwInit() == 0) {
        c.glfwTerminate();
        panic("[ОШИБКА]:Инициализация GLFW завершилось ошибкой!\n", .{});
    } else {
        print("[УСПЕХ]:Инициализация GLFW завершилось успешно\n", .{});
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
            panic("[ОШИБКА]:Создание окна завершилось ошибкой!\n", .{});
        }
        c.glfwMakeContextCurrent(handle);
        if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.glfwGetProcAddress)) == 0) {
            terminate();
            panic("[ОШИБКА]:Инициализация GLAD завершилось ошибкой!\n", .{});
        }
        c.glViewport(0, 0, 800, 600);
        c.glfwSwapInterval(0);

        _ = c.glfwSetWindowSizeCallback(handle, window_size_callback);
        _ = c.glfwSetKeyCallback(handle, key_callback);

        print("[СОЗДАН]:Главное окно[Название:{s}|Ширина:{}|Высота{}]\n", .{ title, width, height });
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
        print("[УНИЧНОЖЕНО]:Главное окно[Название:{s}|Ширина:{}|Высота{}]\n", .{ self.title, self.getSize().x, self.getSize().y });
        c.glfwDestroyWindow(self.handle);
    }
};

var keys: [1032]bool = [_]bool{false} ** 1032;
var frames: [1032]u32 = [_]u32{0} ** 1032;
var current: u32 = 0;

pub fn isPressed(keycode: i32) bool {
    if (keycode < 0 or keycode >= 1024) return false;
    return keys[@intCast(usize, keycode)];
}

pub fn isJustPressed(keycode: i32) bool {
    if (keycode < 0 or keycode >= 1024) return false;
    return keys[@intCast(usize, keycode)] and (frames[@intCast(usize, keycode)] == current);
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

fn window_size_callback(handle: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = handle;
    c.glViewport(0, 0, width, height);
}
