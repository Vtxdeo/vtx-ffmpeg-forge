const std = @import("std");
const core = @import("core_profile");
const rules = @import("core_rules");

pub fn generateConfigureArgs(
    allocator: std.mem.Allocator,
    profile: core.Profile,
    target: std.Target,
) ![]const []const u8 {
    var args = std.ArrayList([]const u8).empty;
    errdefer args.deinit(allocator);

    const adjusted = rules.applyTargetRules(profile, target);

    if (!adjusted.validate()) {
        return error.InvalidProfile;
    }

    try args.append(allocator, "--disable-everything");

    if (adjusted.enable_asm) {
        try args.append(allocator, "--enable-asm");
    } else {
        try args.append(allocator, "--disable-asm");
    }

    for (adjusted.enabled_decoders) |decoder| {
        try args.append(allocator, core.codecToConfigureFlag(decoder));
    }

    for (adjusted.enabled_filters) |filter| {
        try args.append(allocator, core.filterToConfigureFlag(filter));
    }

    for (adjusted.extra_flags) |flag| {
        try args.append(allocator, flag);
    }

    return args.toOwnedSlice(allocator);
}
