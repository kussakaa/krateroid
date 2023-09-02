const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "krateroid",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("SDL2");
    //exe.linkSystemLibrary("freetype2");
    exe.addCSourceFile(.{ .file = .{ .path = "deps/fnl/fnl.c" }, .flags = &.{
        "-std=c99",
        "-fno-sanitize=undefined",
        "-O3",
    } });
    exe.addCSourceFile(.{ .file = .{ .path = "deps/stb/image.c" }, .flags = &.{
        "-std=c99",
        "-fno-sanitize=undefined",
        "-O3",
    } });
    exe.addCSourceFile(.{ .file = .{ .path = "deps/glad/src/glad.c" }, .flags = &.{"-std=c99"} });
    exe.addIncludePath(.{ .path = "deps/" });
    exe.addIncludePath(.{ .path = "deps/glad/include" });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
