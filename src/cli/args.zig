const std = @import("std");

pub fn parseArgs(args: []const [:0]u8) ![]const u8 {
    var index: usize = 1;
    if (std.mem.eql(u8, std.mem.span(args[index]), "build")) {
        index += 1;
    }

    var config_path: ?[]const u8 = null;
    while (index < args.len) : (index += 1) {
        const arg: []const u8 = std.mem.span(args[index]);
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

pub fn printUsage() void {
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
