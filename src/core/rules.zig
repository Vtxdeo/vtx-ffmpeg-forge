const std = @import("std");
const Profile = @import("profile.zig").Profile;

pub fn applyTargetRules(profile: Profile, target: std.Target) Profile {
    var adjusted = profile;

    if (target.cpu.arch == .arm or target.cpu.arch == .armeb) {
        adjusted.enable_asm = false;
    }

    return adjusted;
}
