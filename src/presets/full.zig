const core = @import("../core/profile.zig");

pub fn get() core.Profile {
    return .{
        .enabled_decoders = &.{ .h264, .hevc, .vp9 },
        .enabled_filters = &.{ .scale, .fps, .crop },
        .extra_flags = &.{ "--enable-gpl" },
        .enable_asm = true,
    };
}
