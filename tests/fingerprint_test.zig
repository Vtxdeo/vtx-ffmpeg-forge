const std = @import("std");
const fingerprint = @import("cli_fingerprint");

test "fingerprint with git hash adds g prefix" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try fingerprint.buildFingerprint(
        arena.allocator(),
        "vtx-forge",
        "0.1.10",
        "7a8b9c",
        "nano",
    );
    try std.testing.expectEqualStrings("vtx-forge-v0.1.10-nano-g7a8b9c", value);
}

test "fingerprint keeps g-prefixed hash" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try fingerprint.buildFingerprint(
        arena.allocator(),
        "vtx-forge",
        "0.1.10",
        "g7a8b9c",
        "full",
    );
    try std.testing.expectEqualStrings("vtx-forge-v0.1.10-full-g7a8b9c", value);
}

test "fingerprint omits empty hash" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try fingerprint.buildFingerprint(
        arena.allocator(),
        "vtx-forge",
        "0.1.10",
        "",
        "custom",
    );
    try std.testing.expectEqualStrings("vtx-forge-v0.1.10-custom", value);
}
