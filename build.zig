const std = @import("std");
const rlz = @import("raylib-zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const exe = b.addExecutable(.{ .name = "OpenIVC-Client", .root_source_file = b.path("src/main.zig"), .optimize = optimize, .target = target });
    exe.addCSourceFile(.{ .file = b.path("src/c-code/client.c") });
    exe.addIncludePath(b.path("src/c-code"));

    exe.linkLibrary(raylib_artifact);
    b.installBinFile("src/c-code/ts3client.dll", "ts3client.dll");

    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);
    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run OpenIVC-Client");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
