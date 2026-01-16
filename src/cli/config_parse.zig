const std = @import("std");

const ExistingDir = struct {
    path: []const u8,

    pub fn init(path: []const u8) !ExistingDir {
        var dir = std.fs.cwd().openDir(path, .{}) catch return error.InvalidFfmpegSource;
        defer dir.close();

        var configure = dir.openFile("configure", .{}) catch return error.InvalidFfmpegSource;
        configure.close();

        return .{ .path = path };
    }
};

pub fn RawJsonConfig(comptime ProfileType: type) type {
    return struct {
        ffmpeg_source: []const u8,
        build_dir: ?[]const u8 = null,
        install_dir: ?[]const u8 = null,
        target: ?[]const u8 = null,
        make_jobs: ?u32 = null,
        preset: ?[]const u8 = null,
        profile: ?ProfileType = null,
    };
}

pub fn JsonConfig(comptime ProfileType: type) type {
    return struct {
        ffmpeg_source: ExistingDir,
        build_dir: ?[]const u8 = null,
        install_dir: ?[]const u8 = null,
        target: ?[]const u8 = null,
        make_jobs: ?u32 = null,
        preset: ?[]const u8 = null,
        profile: ?ProfileType = null,
    };
}

pub fn parseConfig(
    allocator: std.mem.Allocator,
    config_raw: []const u8,
    comptime ProfileType: type,
) !JsonConfig(ProfileType) {
    const parsed = std.json.parseFromSlice(RawJsonConfig(ProfileType), allocator, config_raw, .{
        .ignore_unknown_fields = true,
    }) catch return error.InvalidConfig;
    const raw = parsed.value;

    return .{
        .ffmpeg_source = try ExistingDir.init(raw.ffmpeg_source),
        .build_dir = raw.build_dir,
        .install_dir = raw.install_dir,
        .target = raw.target,
        .make_jobs = raw.make_jobs,
        .preset = raw.preset,
        .profile = raw.profile,
    };
}
