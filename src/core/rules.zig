const std = @import("std");
const Profile = @import("core_profile").Profile;

pub fn applyTargetRules(profile: Profile, target: std.Target) !Profile {
    var adjusted = profile;

    if (adjusted.hardware_acceleration and target.cpu.arch == .wasm32) {
        return error.IncompatibleFeature;
    }

    const allow_asm = switch (target.cpu.arch) {
        .x86, .x86_64, .aarch64, .arm, .mipsel => true,
        else => false,
    };

    if (!allow_asm) {
        adjusted.enable_asm = false;
    }

    return adjusted;
}
