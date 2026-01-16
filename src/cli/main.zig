const std = @import("std");
const core = @import("core_profile");
const config_gen = @import("config");
const preset_nano = @import("preset_nano");
const preset_full = @import("preset_full");
const cli_args = @import("cli_args");
const cli_command = @import("cli_command");
const cli_config = @import("cli_config");

const JsonProfile = struct {
    enabled_decoders: ?[]const []const u8 = null,
    enabled_filters: ?[]const []const u8 = null,
    extra_flags: ?[]const []const u8 = null,
    enable_asm: ?bool = null,
    hardware_acceleration: ?bool = null,
};
const JsonConfig = cli_config.JsonConfig(JsonProfile);

const ProfileBundle = struct {
    profile: core.Profile,
    decoders: []const []const u8,
    filters: []const []const u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 2) {
        cli_args.printUsage();
        return error.InvalidArgs;
    }

    const config_path = try cli_args.parseArgs(args);
    const config_raw = try std.fs.cwd().readFileAlloc(allocator, config_path, 1024 * 1024);

    const cfg = try cli_config.parseConfig(allocator, config_raw, JsonProfile);

    const target = try resolveTarget(cfg.target);
    const profile_bundle = try resolveProfile(cfg);
    const configure_args = try config_gen.generateConfigureArgs(allocator, profile_bundle.profile, target);

    const build_dir = cfg.build_dir orelse "build";
    try std.fs.cwd().makePath(build_dir);

    const configure_path = try std.fs.path.join(allocator, &.{ cfg.ffmpeg_source.path, "configure" });
    var configure_argv = std.ArrayList([]const u8).empty;
    try configure_argv.append(allocator, configure_path);

    if (cfg.install_dir) |install_dir| {
        const prefix_arg = try std.fmt.allocPrint(allocator, "--prefix={s}", .{install_dir});
        try configure_argv.append(allocator, prefix_arg);
    }

    for (configure_args) |arg| {
        try configure_argv.append(allocator, arg);
    }

    try cli_command.runCommand(allocator, build_dir, configure_argv.items);

    var make_argv = std.ArrayList([]const u8).empty;
    try make_argv.append(allocator, "make");
    if (cfg.make_jobs) |jobs| {
        const jobs_arg = try std.fmt.allocPrint(allocator, "-j{d}", .{jobs});
        try make_argv.append(allocator, jobs_arg);
    }

    try cli_command.runCommand(allocator, build_dir, make_argv.items);
}

fn resolveTarget(target_str: ?[]const u8) !std.Target {
    var target = std.builtin.target;
    if (target_str == null or std.mem.eql(u8, target_str.?, "native")) {
        return target;
    }

    const value = target_str.?;
    if (std.mem.eql(u8, value, "x86")) {
        target.cpu.arch = .x86;
    } else if (std.mem.eql(u8, value, "x86_64")) {
        target.cpu.arch = .x86_64;
    } else if (std.mem.eql(u8, value, "aarch64")) {
        target.cpu.arch = .aarch64;
    } else if (std.mem.eql(u8, value, "wasm32")) {
        target.cpu.arch = .wasm32;
    } else if (std.mem.eql(u8, value, "wasm64")) {
        target.cpu.arch = .wasm64;
    } else {
        return error.InvalidTarget;
    }

    return target;
}

fn parseConfig(allocator: std.mem.Allocator, config_raw: []const u8) !JsonConfig {
    const parsed = try std.json.parseFromSlice(RawJsonConfig, allocator, config_raw, .{
        .ignore_unknown_fields = true,
    });
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

fn resolveProfile(cfg: JsonConfig) !ProfileBundle {
    if (cfg.preset != null and cfg.profile != null) {
        return error.ConflictingProfileConfig;
    }

    if (cfg.preset) |preset_name| {
        if (std.mem.eql(u8, preset_name, "nano")) {
            return .{ .profile = preset_nano.get(), .decoders = &.{}, .filters = &.{} };
        }
        if (std.mem.eql(u8, preset_name, "full")) {
            return .{ .profile = preset_full.get(), .decoders = &.{}, .filters = &.{} };
        }
        return error.UnknownPreset;
    }

    const profile_json = cfg.profile orelse return error.MissingProfile;
    const decoder_names = profile_json.enabled_decoders orelse return error.MissingDecoders;
    const filter_names = profile_json.enabled_filters orelse return error.MissingFilters;

    const decoders = decoder_names;
    const filters = filter_names;

    const enable_asm = profile_json.enable_asm orelse true;
    const hardware_acceleration = profile_json.hardware_acceleration orelse false;
    const extra_flags = profile_json.extra_flags orelse &.{};

    return .{
        .profile = .{
            .enabled_decoders = decoders,
            .enabled_filters = filters,
            .extra_flags = extra_flags,
            .enable_asm = enable_asm,
            .hardware_acceleration = hardware_acceleration,
        },
        .decoders = decoders,
        .filters = filters,
    };
}
