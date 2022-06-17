const std = @import("std");

pub fn addRunStep(b: *std.build.Builder, exe: *std.build.LibExeObjStep, comptime suffix: []const u8) void {
}

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // Common library
    const common = std.build.Pkg {
        .name = "common",
        .path = "common/lib.zig",
    };

    {
        const fixed_size_queue_test = b.addTest("common/fixed_size_queue.zig");
        
        const test_step = b.step("test-common", "Test the common package");
        test_step.dependOn(&fixed_size_queue_test.step);
    }

    // Smol-emu
    {
        const exe = b.addExecutable("smol-emu", "src/emulator/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addPackage(common);
        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(&exe.step);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run-emu", "Run the emulator");
        run_step.dependOn(&run_cmd.step);

        const cpu_test = b.addTest("src/emulator/cpu.zig");
        cpu_test.addPackage(common);

        const test_step = b.step("test-emu", "Test the emulator");
        test_step.dependOn(&cpu_test.step);
    }
}
