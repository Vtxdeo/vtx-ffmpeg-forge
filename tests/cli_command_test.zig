const std = @import("std");
const builtin = @import("builtin");
const cli_command = @import("cli_command");

fn successCommand() []const []const u8 {
    return if (builtin.os.tag == .windows)
        &.{ "cmd", "/c", "exit", "0" }
    else
        &.{ "sh", "-c", "exit 0" };
}

fn failureCommand() []const []const u8 {
    return if (builtin.os.tag == .windows)
        &.{ "cmd", "/c", "exit", "1" }
    else
        &.{ "sh", "-c", "exit 1" };
}

test "runCommand succeeds on zero exit" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    try cli_command.runCommand(arena.allocator(), ".", successCommand());
}

test "runCommand fails on non-zero exit" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    try std.testing.expectError(error.CommandFailed, cli_command.runCommand(arena.allocator(), ".", failureCommand()));
}
