const std = @import("std");
const Profile = @import("core_profile").Profile;

pub fn applyTargetRules(profile: Profile, target: std.Target) Profile {
    var adjusted = profile;

    const allow_asm = switch (target.cpu.arch) {
        .x86, .x86_64, .aarch64 => true,
        else => false,
    };

    if (!allow_asm) {
        adjusted.enable_asm = false;
    }

    return adjusted;
}
