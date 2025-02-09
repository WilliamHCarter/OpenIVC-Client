const std = @import("std");
const rlz = @import("raylib-zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const miniaudio = b.addSystemCommand(&.{
        "curl",
        "-o",
        "libs/miniaudio.h",
        "-L",
        "https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h",
        "--create-dirs",
    });
    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const exe = b.addExecutable(.{
        .name = "OpenIVC-Client",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });

    exe.step.dependOn(&miniaudio.step);
    exe.addIncludePath(.{ .path = "libs" });
    exe.linkLibC();

    if (target.result.os.tag == .windows) {
        exe.addCSourceFile(.{ .file = b.path("src/c-code/client.c") });
        exe.addIncludePath(b.path("src/c-code"));
        b.installBinFile("src/c-code/ts3client.dll", "ts3client.dll");
    }

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run OpenIVC-Client");
    run_step.dependOn(&run_cmd.step);
    b.installArtifact(exe);
}
