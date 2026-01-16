const std = @import("std");

const prefix = "vtx-ffmpeg-forge: ";

fn emit(writer: anytype, msg: []const u8) void {
    _ = writer.writeAll(prefix) catch {};
    _ = writer.writeAll(msg) catch {};
    _ = writer.writeAll("\n") catch {};
}

pub fn reportError(err: anyerror) bool {
    const stderr = std.fs.File.stderr().writer();
    switch (err) {
        error.InvalidArgs => {
            return true;
        },
        error.ConfigNotFound => {
            emit(stderr, "Config file not found.");
            return true;
        },
        error.ConfigAccessDenied => {
            emit(stderr, "Permission denied when reading config file.");
            return true;
        },
        error.ConfigIsDirectory => {
            emit(stderr, "Config path points to a directory, not a file.");
            return true;
        },
        error.ConfigInvalidPath => {
            emit(stderr, "Config path is invalid.");
            return true;
        },
        error.ConfigReadFailed => {
            emit(stderr, "Failed to read config file.");
            return true;
        },
        error.InvalidConfig => {
            emit(stderr, "Invalid config JSON.");
            return true;
        },
        error.InvalidFfmpegSource => {
            emit(stderr, "ffmpeg_source must be a directory containing ./configure.");
            return true;
        },
        error.InvalidTarget => {
            emit(stderr, "Invalid target; use native/x86/x86_64/aarch64/wasm32/wasm64.");
            return true;
        },
        error.ConflictingProfileConfig => {
            emit(stderr, "Use either preset or profile, not both.");
            return true;
        },
        error.UnknownPreset => {
            emit(stderr, "Unknown preset; use nano or full.");
            return true;
        },
        error.MissingProfile => {
            emit(stderr, "Missing profile; provide preset or profile.");
            return true;
        },
        error.MissingDecoders => {
            emit(stderr, "Missing profile.enabled_decoders array.");
            return true;
        },
        error.MissingFilters => {
            emit(stderr, "Missing profile.enabled_filters array.");
            return true;
        },
        error.InvalidProfile => {
            emit(stderr, "Invalid profile; incompatible flags or empty selection.");
            return true;
        },
        error.IncompatibleFeature => {
            emit(stderr, "Hardware acceleration is incompatible with wasm targets.");
            return true;
        },
        error.CommandFailed => {
            emit(stderr, "Command failed; see output above.");
            return true;
        },
        else => return false,
    }
}
