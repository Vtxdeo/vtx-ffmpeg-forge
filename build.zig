const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.option([]const u8, "profile", "Profile name (nano/full)") orelse "nano";

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "tests/generator_test.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run logic-layer tests");
    test_step.dependOn(&tests.step);
}
