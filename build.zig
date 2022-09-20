const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const ptgen_lib = b.addSharedLibrary("ptgen", "src/ptgen.zig", .unversioned);
    ptgen_lib.setTarget(target);
    ptgen_lib.setBuildMode(mode);
    ptgen_lib.install();

    const hfs = "/opt/hfs19.0";
    const hfs_dsolib = hfs ++ "/dsolib";
    const hfs_include = hfs ++ "/toolkit/include";

    const hengine_lib = b.addSharedLibrary("hengine", "src/hengine.zig", .unversioned);
    hengine_lib.addSystemIncludePath(hfs_include);
    hengine_lib.addLibraryPath(hfs_dsolib);
    hengine_lib.linkSystemLibrary("HAPI");
    hengine_lib.linkLibC();
    hengine_lib.setTarget(target);
    hengine_lib.setBuildMode(mode);
    hengine_lib.install();

    const exe = b.addExecutable("zig_engine", "src/main.zig");
    exe.addSystemIncludePath(hfs_include);
    exe.addLibraryPath(hfs_dsolib);
    exe.linkSystemLibrary("HAPI");
    exe.linkLibC();
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run Tests");
    const tests = b.addTest("src/tests.zig");
    tests.setBuildMode(mode);
    test_step.dependOn(&tests.step);
}
