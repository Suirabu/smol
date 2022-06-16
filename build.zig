const std = @import("std");

pub fn addExecutableWithStep(b: *std.build.Builder, comptime suffix: []const u8, root_src: ?[]const u8) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe_name = "smol-" ++ suffix;
    const exe = b.addExecutable(exe_name, root_src);
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    
    const run_cmd = exe.run();
    run_cmd.step.dependOn(&exe.step);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run-" ++ suffix, "Run " ++ exe_name);
    run_step.dependOn(&run_cmd.step);
}

pub fn build(b: *std.build.Builder) void {
    addExecutableWithStep(b, "emu", "src/emulator/main.zig");
}
