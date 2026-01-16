const std = @import("std");
const cli_errors = @import("cli_errors");

test "reportError returns true for known errors" {
    try std.testing.expect(cli_errors.reportError(error.InvalidArgs));
    try std.testing.expect(cli_errors.reportError(error.InvalidConfig));
}

test "reportError returns false for unknown errors" {
    try std.testing.expect(!cli_errors.reportError(error.OutOfMemory));
}
