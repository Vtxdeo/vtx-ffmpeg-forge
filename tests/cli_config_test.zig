const std = @import("std");
const cli_config = @import("cli_config");

const TestProfile = struct {
    enabled_decoders: ?[]const []const u8 = null,
    enabled_filters: ?[]const []const u8 = null,
    extra_flags: ?[]const []const u8 = null,
    enable_asm: ?bool = null,
    hardware_acceleration: ?bool = null,
    disable_everything: ?bool = null,
};

test "config parse ignores unknown fields" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const json =
        \\{
        \\  "ffmpeg_source": "ffmpeg",
        \\  "preset": "nano",
        \\  "unknown": 42
        \\}
    ;
    const cfg = try cli_config.parseConfig(arena.allocator(), json, TestProfile);
    try std.testing.expectEqualStrings("ffmpeg", cfg.ffmpeg_source);
    try std.testing.expect(cfg.preset != null);
}

test "config parse rejects invalid json" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const json = "{ invalid json";
    try std.testing.expectError(error.InvalidConfig, cli_config.parseConfig(arena.allocator(), json, TestProfile));
}
