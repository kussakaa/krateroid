const std = @import("std");
const Builder = std.build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("krateroid", "src/main.zig");
    exe.linkSystemLibrary("c");
    exe.linkLibC();
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("freetype2");
    exe.addIncludePath("deps/fnl");
    exe.addCSourceFile("deps/fnl/FastNoiseLite.c", &.{ "-std=c99", "-fno-sanitize=undefined", "-O3" });
    exe.addIncludePath("deps/glad/include");
    exe.addCSourceFile("deps/glad/src/glad.c", &.{"-std=c99"});
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
