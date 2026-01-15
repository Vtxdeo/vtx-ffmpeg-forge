const core = @import("core_profile");

pub fn get() core.Profile {
    return .{
        .enabled_decoders = &.{ .h264 },
        .enabled_filters = &.{ .scale },
        .extra_flags = &.{ "--enable-small" },
        .enable_asm = true,
        .hardware_acceleration = false,
    };
}
