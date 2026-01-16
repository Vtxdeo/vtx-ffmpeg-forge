const std = @import("std");

const prefix = "vtx-ffmpeg-forge: ";

fn emit(msg: []const u8) void {
    std.debug.print("{s}{s}\n", .{ prefix, msg });
}

pub fn reportError(err: anyerror) bool {
    switch (err) {
        error.InvalidArgs => {
            return true;
        },
        error.ConfigNotFound => {
            emit("Config file not found.");
            return true;
        },
        error.ConfigAccessDenied => {
            emit("Permission denied when reading config file.");
            return true;
        },
        error.ConfigIsDirectory => {
            emit("Config path points to a directory, not a file.");
            return true;
        },
        error.ConfigInvalidPath => {
            emit("Config path is invalid.");
            return true;
        },
        error.ConfigReadFailed => {
            emit("Failed to read config file.");
            return true;
        },
        error.InvalidConfig => {
            emit("Invalid config JSON.");
            return true;
        },
        error.InvalidFfmpegSource => {
            emit("ffmpeg_source must be a directory containing ./configure.");
            return true;
        },
        error.InvalidTarget => {
            emit("Invalid target; use native/x86/x86_64/aarch64/wasm32/wasm64.");
            return true;
        },
        error.ConflictingProfileConfig => {
            emit("Use either preset or profile, not both.");
            return true;
        },
        error.UnknownPreset => {
            emit("Unknown preset; use nano or full.");
            return true;
        },
        error.MissingProfile => {
            emit("Missing profile; provide preset or profile.");
            return true;
        },
        error.MissingDecoders => {
            emit("Missing profile.enabled_decoders array.");
            return true;
        },
        error.MissingFilters => {
            emit("Missing profile.enabled_filters array.");
            return true;
        },
        error.InvalidProfile => {
            emit("Invalid profile; incompatible flags or empty selection.");
            return true;
        },
        error.IncompatibleFeature => {
            emit("Hardware acceleration is incompatible with wasm targets.");
            return true;
        },
        error.CommandFailed => {
            emit("Command failed; see output above.");
            return true;
        },
        else => return false,
    }
}
