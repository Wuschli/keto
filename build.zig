const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary("keto", "src/keto.zig", b.version(0, 0, 1));
    lib.linkLibC();
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.install();

    const cli = b.addExecutable("keto", "src/main.zig");
    cli.linkLibC();
    cli.setTarget(target);
    // cli.setBuildMode(mode);
    cli.install();

    const tests = b.addTest("src/keto.zig");
    tests.linkLibC();
    tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.step);
}
