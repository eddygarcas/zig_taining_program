const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "kernal",
        .root_module = b.createModule(.{
            // b.createModule defines a new module just like b.addModule but,
            // unlike b.addModule, it does not expose the module to consumers of
            // this package, which is why in this case we don't have to give it a name.
            .root_source_file = b.path("kernel.zig"),
            // Target and optimization levels must be explicitly wired in when
            // defining an executable or library (in the root module), and you
            // can also hardcode a specific target for an executable or library
            // definition if desireable (e.g. firmware for embedded devices).
            .target = target,
            .optimize = optimize,
            // List of modules available for import in source files part of the
            // root module.
        }),
    });
    exe.setLinkerScript(.{ .src_path = .{ .owner = b, .sub_path = "link.ld" } });

    const bootloader = b.addSystemCommand(&.{ "nasm", "-f", "bin", "boot.asm", "-o", "boot.bin" });

    const combine = b.addSystemCommand(&.{ "sh", "-c", "cat build/boot.bin build/kernal > build/disk.img" });

    combine.step.dependOn(&bootloader.step);
    combine.step.dependOn(&exe.step);

    b.installArtifact(exe);
    b.installFile("disk.img", "disk.img");
}
