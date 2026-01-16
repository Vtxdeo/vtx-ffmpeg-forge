const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.option([]const u8, "profile", "Profile name (nano/full)") orelse "nano";

    const core_profile_module = b.createModule(.{
        .root_source_file = b.path("src/core/profile.zig"),
        .target = target,
        .optimize = optimize,
    });
    const core_rules_module = b.createModule(.{
        .root_source_file = b.path("src/core/rules.zig"),
        .imports = &.{
            .{ .name = "core_profile", .module = core_profile_module },
        },
        .target = target,
        .optimize = optimize,
    });
    const config_module = b.createModule(.{
        .root_source_file = b.path("src/generator/config.zig"),
        .imports = &.{
            .{ .name = "core_profile", .module = core_profile_module },
            .{ .name = "core_rules", .module = core_rules_module },
        },
        .target = target,
        .optimize = optimize,
    });
    const nano_module = b.createModule(.{
        .root_source_file = b.path("src/presets/nano.zig"),
        .imports = &.{
            .{ .name = "core_profile", .module = core_profile_module },
        },
        .target = target,
        .optimize = optimize,
    });
    const full_module = b.createModule(.{
        .root_source_file = b.path("src/presets/full.zig"),
        .imports = &.{
            .{ .name = "core_profile", .module = core_profile_module },
        },
        .target = target,
        .optimize = optimize,
    });
    const test_module = b.createModule(.{
        .root_source_file = b.path("tests/generator_test.zig"),
        .imports = &.{
            .{ .name = "config", .module = config_module },
            .{ .name = "nano", .module = nano_module },
        },
        .target = target,
        .optimize = optimize,
    });
    const tests = b.addTest(.{
        .root_module = test_module,
    });

    const cli_module = b.createModule(.{
        .root_source_file = b.path("src/cli/main.zig"),
        .imports = &.{
            .{ .name = "config", .module = config_module },
            .{ .name = "core_profile", .module = core_profile_module },
            .{ .name = "preset_nano", .module = nano_module },
            .{ .name = "preset_full", .module = full_module },
            .{ .name = "cli_args", .module = b.createModule(.{ .root_source_file = b.path("src/cli/args.zig"), .target = target, .optimize = optimize }) },
            .{ .name = "cli_command", .module = b.createModule(.{ .root_source_file = b.path("src/cli/command.zig"), .target = target, .optimize = optimize }) },
            .{ .name = "cli_config", .module = b.createModule(.{ .root_source_file = b.path("src/cli/config_parse.zig"), .target = target, .optimize = optimize }) },
        },
        .target = target,
        .optimize = optimize,
    });
    const cli = b.addExecutable(.{
        .name = "vtx-ffmpeg-forge",
        .root_module = cli_module,
    });
    b.installArtifact(cli);

    const test_step = b.step("test", "Run logic-layer tests");
    test_step.dependOn(&tests.step);
}
