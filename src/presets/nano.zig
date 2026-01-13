const core = @import("../core/profile.zig");

pub fn get() core.Profile {
    return .{
        .enabled_decoders = &.{ .h264 },
        .enabled_filters = &.{ .scale },
        .extra_flags = &.{ "--enable-small" },
        .enable_asm = true,
    };
}
