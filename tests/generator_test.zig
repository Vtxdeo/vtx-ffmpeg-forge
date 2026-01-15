const std = @import("std");
const config = @import("config");
const nano = @import("nano");

fn hasArg(args: []const []const u8, needle: []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, needle)) return true;
    }
    return false;
}

test "generate config args for nano" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const target_query = std.Target.Query{ .cpu_arch = .x86_64, .os_tag = .linux };
    const target = std.zig.resolveTargetQueryOrFatal(target_query);
    const args = try config.generateConfigureArgs(
        arena.allocator(),
        nano.get(),
        target,
    );

    try std.testing.expect(hasArg(args, "--disable-everything"));
    try std.testing.expect(hasArg(args, "--enable-decoder=h264"));
    try std.testing.expect(hasArg(args, "--enable-filter=scale"));
}

test "enable asm for x86_64" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const target_query = std.Target.Query{ .cpu_arch = .x86_64, .os_tag = .linux };
    const target = std.zig.resolveTargetQueryOrFatal(target_query);
    const args = try config.generateConfigureArgs(
        arena.allocator(),
        nano.get(),
        target,
    );

    try std.testing.expect(hasArg(args, "--enable-asm"));
    try std.testing.expect(!hasArg(args, "--disable-asm"));
}

test "disable asm for wasm32" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const target_query = std.Target.Query{ .cpu_arch = .wasm32, .os_tag = .freestanding };
    const target = std.zig.resolveTargetQueryOrFatal(target_query);
    const args = try config.generateConfigureArgs(
        arena.allocator(),
        nano.get(),
        target,
    );

    try std.testing.expect(hasArg(args, "--disable-asm"));
    try std.testing.expect(!hasArg(args, "--enable-asm"));
}
