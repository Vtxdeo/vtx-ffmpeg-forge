const std = @import("std");

pub const Codec = enum {
    h264,
    hevc,
    vp9,
};

pub const Filter = enum {
    scale,
    fps,
    crop,
};

pub const Profile = struct {
    enabled_decoders: []const Codec,
    enabled_filters: []const Filter,
    extra_flags: []const []const u8,
    enable_asm: bool,
    hardware_acceleration: bool,

    pub fn validate(self: Profile) bool {
        return self.enabled_decoders.len > 0;
    }
};

pub fn codecToConfigureFlag(codec: Codec) []const u8 {
    return switch (codec) {
        .h264 => "--enable-decoder=h264",
        .hevc => "--enable-decoder=hevc",
        .vp9 => "--enable-decoder=vp9",
    };
}

pub fn filterToConfigureFlag(filter: Filter) []const u8 {
    return switch (filter) {
        .scale => "--enable-filter=scale",
        .fps => "--enable-filter=fps",
        .crop => "--enable-filter=crop",
    };
}
