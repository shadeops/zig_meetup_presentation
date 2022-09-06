const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const ptgen_lib = b.addSharedLibrary("ptgen", "src/ptgen.zig", .unversioned);
    ptgen_lib.setBuildMode(mode);
    ptgen_lib.install();

    const hfs = "/opt/hfs19.0";
    const hfs_dsolib = hfs ++ "/dsolib";
    const hfs_include = hfs ++ "/toolkit/include"; 

    const hengine_lib = b.addSharedLibrary("hengine", "src/hengine.zig", .unversioned);
    hengine_lib.addSystemIncludeDir(hfs_include);
    hengine_lib.addLibPath(hfs_dsolib);
    hengine_lib.linkSystemLibrary("HAPIL");
    hengine_lib.linkLibC();
    hengine_lib.setBuildMode(mode);
    hengine_lib.install();

    const test_step = b.step("test", "Run Tests");
    const tests = b.addTest("src/tests.zig");
    tests.setBuildMode(mode);
    test_step.dependOn(&tests.step);
}
