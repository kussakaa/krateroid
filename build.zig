const std = @import("std");
const zmath = @import("deps/zig-gamedev/libs/zmath/build.zig");
const znoise = @import("deps/zig-gamedev/libs/znoise/build.zig");
const zopengl = @import("deps/zig-gamedev/libs/zopengl/build.zig");
const zsdl = @import("deps/zig-gamedev/libs/zsdl/build.zig");
const zstbi = @import("deps/zig-gamedev/libs/zstbi/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "krateroid",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const zmath_pkg = zmath.package(b, target, optimize, .{});
    zmath_pkg.link(exe);

    const znoise_pkg = znoise.package(b, target, optimize, .{});
    znoise_pkg.link(exe);

    const zopengl_pkg = zopengl.package(b, target, optimize, .{}); // .options = .{ .api = .wrapper }
    zopengl_pkg.link(exe);

    const zsdl_pkg = zsdl.package(b, target, optimize, .{});
    zsdl_pkg.link(exe);

    const zstbi_pkg = zstbi.package(b, target, optimize, .{});
    zstbi_pkg.link(exe);

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
