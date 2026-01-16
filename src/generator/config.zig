const std = @import("std");
const core = @import("core_profile");
const rules = @import("core_rules");

pub fn generateConfigureArgs(
    allocator: std.mem.Allocator,
    profile: core.Profile,
    target: std.Target,
    extra_version: ?[]const u8,
) ![]const []const u8 {
    var args = std.ArrayList([]const u8).empty;
    errdefer args.deinit(allocator);

    const adjusted = try rules.applyTargetRules(profile, target);

    if (!adjusted.validate()) {
        return error.InvalidProfile;
    }

    if (extra_version) |version| {
        const flag = try std.fmt.allocPrint(allocator, "--extra-version={s}", .{version});
        try args.append(allocator, flag);
    }

    if (adjusted.disable_everything) {
        try args.append(allocator, "--disable-everything");
    }

    if (adjusted.enable_asm) {
        try args.append(allocator, "--enable-asm");
    } else {
        try args.append(allocator, "--disable-asm");
    }

    for (adjusted.enabled_decoders) |decoder| {
        const flag = try std.fmt.allocPrint(allocator, "--enable-decoder={s}", .{decoder});
        try args.append(allocator, flag);
    }

    for (adjusted.enabled_filters) |filter| {
        const flag = try std.fmt.allocPrint(allocator, "--enable-filter={s}", .{filter});
        try args.append(allocator, flag);
    }

    for (adjusted.extra_flags) |flag| {
        try args.append(allocator, flag);
    }

    return args.toOwnedSlice(allocator);
}
