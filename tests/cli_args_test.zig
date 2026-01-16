const std = @import("std");
const cli_args = @import("cli_args");

fn s(comptime value: [:0]const u8) [:0]u8 {
    return @constCast(value);
}

test "args parse supports build subcommand" {
    var args = [_][:0]u8{ s("vtx-ffmpeg-forge"), s("build"), s("-c"), s("config.json") };
    const path = try cli_args.parseArgs(args[0..]);
    try std.testing.expectEqualStrings("config.json", path);
}

test "args parse accepts positional config" {
    var args = [_][:0]u8{ s("vtx-ffmpeg-forge"), s("config.json") };
    const path = try cli_args.parseArgs(args[0..]);
    try std.testing.expectEqualStrings("config.json", path);
}

test "args parse rejects unknown flags" {
    var args = [_][:0]u8{ s("vtx-ffmpeg-forge"), s("--nope") };
    try std.testing.expectError(error.InvalidArgs, cli_args.parseArgs(args[0..]));
}
