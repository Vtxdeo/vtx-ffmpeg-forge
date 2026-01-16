pub const Profile = struct {
    enabled_decoders: []const []const u8,
    enabled_filters: []const []const u8,
    extra_flags: []const []const u8,
    enable_asm: bool,
    hardware_acceleration: bool,

    pub fn validate(self: Profile) bool {
        return self.enabled_decoders.len > 0;
    }
};
