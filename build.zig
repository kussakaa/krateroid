const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "krateroid",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const util_mod = b.createModule(.{ .root_source_file = b.path("src/util.zig") });
    exe.root_module.addImport("util", util_mod);

    const zmath = b.dependency("zmath", .{});
    exe.root_module.addImport("zmath", zmath.module("root"));

    const znoise = b.dependency("znoise", .{});
    exe.root_module.addImport("znoise", znoise.module("root"));
    exe.linkLibrary(znoise.artifact("FastNoiseLite"));

    const zopengl = b.dependency("zopengl", .{});
    exe.root_module.addImport("zopengl", zopengl.module("root"));

    const zsdl = b.dependency("zsdl", .{});
    exe.root_module.addImport("zsdl2", zsdl.module("zsdl2"));
    @import("zsdl").addLibraryPathsTo(exe);
    @import("zsdl").link_SDL2(exe);
    @import("zsdl").install_sdl2(&exe.step, target.result, .bin);

    const zstbi = b.dependency("zstbi", .{});
    exe.root_module.addImport("zstbi", zstbi.module("root"));
    exe.linkLibrary(zstbi.artifact("zstbi"));

    const zaudio = b.dependency("zaudio", .{});
    exe.root_module.addImport("zaudio", zaudio.module("root"));
    exe.linkLibrary(zaudio.artifact("miniaudio"));

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
