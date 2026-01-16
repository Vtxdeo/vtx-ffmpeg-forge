const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.option([]const u8, "profile", "Profile name (nano/full)") orelse "nano";
    const pkg_version = readPackageVersion(b) orelse "0.0.0";
    const tool_id = b.option([]const u8, "tool_id", "Fingerprint tool id") orelse "vtx-forge";
    const git_hash = b.option([]const u8, "git_hash", "Fingerprint git short hash") orelse readEnv(b, "VTX_FFMPEG_FORGE_GIT") orelse "";

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "tool_id", tool_id);
    build_options.addOption([]const u8, "version", pkg_version);
    build_options.addOption([]const u8, "git_hash", git_hash);

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
    const cli_module = b.createModule(.{
        .root_source_file = b.path("src/cli/main.zig"),
        .imports = &.{
            .{ .name = "build_options", .module = build_options.createModule() },
            .{ .name = "config", .module = config_module },
            .{ .name = "core_profile", .module = core_profile_module },
            .{ .name = "preset_nano", .module = nano_module },
            .{ .name = "preset_full", .module = full_module },
            .{ .name = "cli_args", .module = b.createModule(.{ .root_source_file = b.path("src/cli/args.zig"), .target = target, .optimize = optimize }) },
            .{ .name = "cli_command", .module = b.createModule(.{ .root_source_file = b.path("src/cli/command.zig"), .target = target, .optimize = optimize }) },
            .{ .name = "cli_config", .module = b.createModule(.{ .root_source_file = b.path("src/cli/config_parse.zig"), .target = target, .optimize = optimize }) },
            .{ .name = "cli_errors", .module = b.createModule(.{ .root_source_file = b.path("src/cli/errors.zig"), .target = target, .optimize = optimize }) },
            .{ .name = "cli_fingerprint", .module = b.createModule(.{ .root_source_file = b.path("src/cli/fingerprint.zig"), .target = target, .optimize = optimize }) },
        },
        .target = target,
        .optimize = optimize,
    });
    const cli = b.addExecutable(.{
        .name = "vtx-ffmpeg-forge",
        .root_module = cli_module,
    });
    b.installArtifact(cli);

    const test_module = b.createModule(.{
        .root_source_file = b.path("tests/all_tests.zig"),
        .imports = &.{
            .{ .name = "config", .module = config_module },
            .{ .name = "nano", .module = nano_module },
            .{ .name = "cli_args", .module = b.createModule(.{ .root_source_file = b.path("src/cli/args.zig"), .target = target, .optimize = optimize }) },
            .{ .name = "cli_command", .module = b.createModule(.{ .root_source_file = b.path("src/cli/command.zig"), .target = target, .optimize = optimize }) },
            .{ .name = "cli_config", .module = b.createModule(.{ .root_source_file = b.path("src/cli/config_parse.zig"), .target = target, .optimize = optimize }) },
            .{ .name = "cli_errors", .module = b.createModule(.{ .root_source_file = b.path("src/cli/errors.zig"), .target = target, .optimize = optimize }) },
            .{ .name = "cli_fingerprint", .module = b.createModule(.{ .root_source_file = b.path("src/cli/fingerprint.zig"), .target = target, .optimize = optimize }) },
        },
        .target = target,
        .optimize = optimize,
    });
    const tests = b.addTest(.{
        .root_module = test_module,
    });

    const test_step = b.step("test", "Run logic-layer tests");
    test_step.dependOn(&tests.step);
}

fn readEnv(b: *std.Build, key: []const u8) ?[]const u8 {
    return std.process.getEnvVarOwned(b.allocator, key) catch null;
}

fn readPackageVersion(b: *std.Build) ?[]const u8 {
    const pkg_data = b.build_root.handle.readFileAlloc(b.allocator, "package.json", 1024 * 1024) catch return null;
    const PackageJson = struct {
        version: []const u8,
    };
    const parsed = std.json.parseFromSlice(PackageJson, b.allocator, pkg_data, .{}) catch return null;
    defer parsed.deinit();
    return b.allocator.dupe(u8, parsed.value.version) catch null;
}
