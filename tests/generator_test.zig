const std = @import("std");
const config = @import("../src/generator/config.zig");
const nano = @import("../src/presets/nano.zig");

fn hasArg(args: []const []const u8, needle: []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, needle)) return true;
    }
    return false;
}

test "generate config args for nano" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const target = std.zig.CrossTarget{ .cpu_arch = .x86_64, .os_tag = .linux };
    const args = try config.generateConfigureArgs(
        arena.allocator(),
        nano.get(),
        target.toTarget(),
    );

    try std.testing.expect(hasArg(args, "--disable-everything"));
    try std.testing.expect(hasArg(args, "--enable-decoder=h264"));
    try std.testing.expect(hasArg(args, "--enable-filter=scale"));
}
