const std = @import("std");
const core = @import("core_profile");
const config_gen = @import("config");
const preset_nano = @import("preset_nano");
const preset_full = @import("preset_full");

const JsonProfile = struct {
    enabled_decoders: ?[]const []const u8 = null,
    enabled_filters: ?[]const []const u8 = null,
    extra_flags: ?[]const []const u8 = null,
    enable_asm: ?bool = null,
    hardware_acceleration: ?bool = null,
};

const JsonConfig = struct {
    ffmpeg_source: []const u8,
    build_dir: ?[]const u8 = null,
    install_dir: ?[]const u8 = null,
    target: ?[]const u8 = null,
    make_jobs: ?u32 = null,
    preset: ?[]const u8 = null,
    profile: ?JsonProfile = null,
};

const ProfileBundle = struct {
    profile: core.Profile,
    decoders: []const core.Codec,
    filters: []const core.Filter,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 2) {
        printUsage();
        return error.InvalidArgs;
    }

    const config_path = try parseArgs(args);
    const config_raw = try std.fs.cwd().readFileAlloc(allocator, config_path, 1024 * 1024);

    const parsed = try std.json.parseFromSlice(JsonConfig, allocator, config_raw, .{
        .ignore_unknown_fields = true,
    });
    const cfg = parsed.value;

    const target = try resolveTarget(cfg.target);
    const profile_bundle = try resolveProfile(allocator, cfg);
    const configure_args = try config_gen.generateConfigureArgs(allocator, profile_bundle.profile, target);

    const build_dir = cfg.build_dir orelse "build";
    try std.fs.cwd().makePath(build_dir);

    const configure_path = try std.fs.path.join(allocator, &.{ cfg.ffmpeg_source, "configure" });
    var configure_argv = std.ArrayList([]const u8).empty;
    try configure_argv.append(allocator, configure_path);

    if (cfg.install_dir) |install_dir| {
        const prefix_arg = try std.fmt.allocPrint(allocator, "--prefix={s}", .{install_dir});
        try configure_argv.append(allocator, prefix_arg);
    }

    for (configure_args) |arg| {
        try configure_argv.append(allocator, arg);
    }

    try runCommand(allocator, build_dir, configure_argv.items);

    var make_argv = std.ArrayList([]const u8).empty;
    try make_argv.append(allocator, "make");
    if (cfg.make_jobs) |jobs| {
        const jobs_arg = try std.fmt.allocPrint(allocator, "-j{d}", .{jobs});
        try make_argv.append(allocator, jobs_arg);
    }

    try runCommand(allocator, build_dir, make_argv.items);
}

fn parseArgs(args: [][]const u8) ![]const u8 {
    var index: usize = 1;
    if (std.mem.eql(u8, args[index], "build")) {
        index += 1;
    }

    var config_path: ?[]const u8 = null;
    while (index < args.len) : (index += 1) {
        const arg = args[index];
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            printUsage();
            return error.InvalidArgs;
        }

        if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--config")) {
            index += 1;
            if (index >= args.len) {
                return error.InvalidArgs;
            }
            config_path = args[index];
            continue;
        }

        if (config_path == null and arg.len > 0 and arg[0] != '-') {
            config_path = arg;
            continue;
        }

        return error.InvalidArgs;
    }

    return config_path orelse error.InvalidArgs;
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

fn resolveProfile(allocator: std.mem.Allocator, cfg: JsonConfig) !ProfileBundle {
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

    var decoders = try allocator.alloc(core.Codec, decoder_names.len);
    for (decoder_names, 0..) |name, idx| {
        decoders[idx] = try parseCodec(name);
    }

    var filters = try allocator.alloc(core.Filter, filter_names.len);
    for (filter_names, 0..) |name, idx| {
        filters[idx] = try parseFilter(name);
    }

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

fn parseCodec(name: []const u8) !core.Codec {
    if (std.mem.eql(u8, name, "h264")) return .h264;
    if (std.mem.eql(u8, name, "hevc")) return .hevc;
    if (std.mem.eql(u8, name, "vp9")) return .vp9;
    return error.InvalidCodec;
}

fn parseFilter(name: []const u8) !core.Filter {
    if (std.mem.eql(u8, name, "scale")) return .scale;
    if (std.mem.eql(u8, name, "fps")) return .fps;
    if (std.mem.eql(u8, name, "crop")) return .crop;
    return error.InvalidFilter;
}

fn runCommand(allocator: std.mem.Allocator, cwd: []const u8, argv: []const []const u8) !void {
    var child = std.process.Child.init(argv, allocator);
    child.cwd = cwd;
    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    const term = try child.spawnAndWait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) return error.CommandFailed;
        },
        else => return error.CommandFailed,
    }
}

fn printUsage() void {
    std.debug.print(
        \\Usage:
        \\  vtx-ffmpeg-forge build -c config.json
        \\  vtx-ffmpeg-forge -c config.json
        \\  vtx-ffmpeg-forge config.json
        \\
        \\Config fields:
        \\  ffmpeg_source (string, required)
        \\  build_dir (string, optional)
        \\  install_dir (string, optional)
        \\  target (string, optional: native/x86/x86_64/aarch64/wasm32/wasm64)
        \\  make_jobs (number, optional)
        \\  preset (string, optional: nano/full)
        \\  profile (object, optional if preset provided)
        \\    enabled_decoders (array of strings)
        \\    enabled_filters (array of strings)
        \\    extra_flags (array of strings, optional)
        \\    enable_asm (bool, optional)
        \\    hardware_acceleration (bool, optional)
        \\
    , .{});
}
