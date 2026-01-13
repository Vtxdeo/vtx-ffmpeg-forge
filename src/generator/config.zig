const std = @import("std");
const core = @import("../core/profile.zig");
const rules = @import("../core/rules.zig");

pub fn generateConfigureArgs(
    allocator: std.mem.Allocator,
    profile: core.Profile,
    target: std.Target,
) ![]const []const u8 {
    var args = std.ArrayList([]const u8).init(allocator);
    errdefer args.deinit();

    const adjusted = rules.applyTargetRules(profile, target);

    if (!adjusted.validate()) {
        return error.InvalidProfile;
    }

    try args.append("--disable-everything");

    if (adjusted.enable_asm) {
        try args.append("--enable-asm");
    } else {
        try args.append("--disable-asm");
    }

    for (adjusted.enabled_decoders) |decoder| {
        try args.append(core.codecToConfigureFlag(decoder));
    }

    for (adjusted.enabled_filters) |filter| {
        try args.append(core.filterToConfigureFlag(filter));
    }

    for (adjusted.extra_flags) |flag| {
        try args.append(flag);
    }

    return args.toOwnedSlice();
}
