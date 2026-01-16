const std = @import("std");

pub fn buildFingerprint(
    allocator: std.mem.Allocator,
    tool_id: []const u8,
    version: []const u8,
    git_hash: []const u8,
    profile_label: []const u8,
) ![]const u8 {
    const base = try std.fmt.allocPrint(
        allocator,
        "{s}-v{s}-{s}",
        .{ tool_id, version, profile_label },
    );

    if (git_hash.len == 0 or std.mem.eql(u8, git_hash, "unknown")) {
        return base;
    }

    const hash = if (git_hash[0] == 'g')
        git_hash
    else
        try std.fmt.allocPrint(allocator, "g{s}", .{git_hash});

    return std.fmt.allocPrint(allocator, "{s}-{s}", .{ base, hash });
}
