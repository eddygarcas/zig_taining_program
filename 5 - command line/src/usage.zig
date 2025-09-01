const std = @import("std");

/// Prints usage information to stderr with color-coded sections
/// Uses TTY (terminal) configuration for colored output:
/// - Cyan: Main usage line
/// - Green: Individual options
/// - Reset: Returns terminal colors to default
/// The TTY config automatically detects terminal capabilities
/// and falls back gracefully if colors aren't supported
///
/// Parameters:
///   name: The program name to show in usage text
pub fn printUsage(name: []const u8) !void {
    const err = std.io.getStdErr().writer();
    const tty_config = std.io.tty.detectConfig(std.io.getStdErr());
    try tty_config.setColor(err, .cyan);
    try err.print("Usage: {s} |options|\n", .{name});
    try tty_config.setColor(err, .green);
    try err.print(" --name <text> Set the greeting name (default: \"name\")\n", .{});
    try err.print(" --count <number> Repeat times (default: 1)\n", .{});
    try err.print(" --verbose Enable verbose output\n", .{});
    try err.print(" --help Show this help message\n", .{});
    try tty_config.setColor(err, .reset);
    try err.print("\n", .{});
}