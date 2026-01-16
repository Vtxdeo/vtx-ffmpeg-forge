const core = @import("core_profile");

pub fn get() core.Profile {
    return .{
        .enabled_decoders = &.{ "h264", "hevc", "vp9" },
        .enabled_filters = &.{ "scale", "fps", "crop" },
        .extra_flags = &.{ "--enable-gpl" },
        .enable_asm = true,
        .hardware_acceleration = false,
        .disable_everything = true,
    };
}
