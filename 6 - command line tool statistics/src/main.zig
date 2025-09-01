//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

/// Standard library import providing core functionality
const std = @import("std");
/// Configuration struct import defining program options
const Config = @import("config.zig").Config;
/// Module for reading numeric input from stdin
const Numbers = @import("read_numbers.zig");
/// Module containing statistical computation functions
const Compute = @import("compute.zig");
/// Module for parsing command line arguments
const Arguments = @import("parser.zig");

/// Main entry point for the statistics calculator
/// Handles command line argument parsing and program execution
/// Uses page allocator for memory management
/// Returns error if argument parsing or execution fails
/// RUN: echo "5 10 15" | zig build run -- --median
pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const cfg = Arguments.parseArgs(args) catch |err| {
        if (err == error.ShowHelp) return;
        return err;
    };
    try run(cfg, allocator);
}

/// Core program execution function
/// Reads numbers from stdin and computes requested statistics
/// Arguments:
///   cfg: Configuration struct containing which statistics to show
///   alloc: Memory allocator for dynamic allocations
/// Returns: Error if input reading or computation fails
fn run(cfg: Config, alloc: std.mem.Allocator) !void {
    const numbers = try Numbers.readNumbers(alloc);
    defer alloc.free(numbers);

    if (numbers.len == 0) {
        try std.io.getStdErr().writer().print("No numbers provided.\n", .{});
        return error.NoInput;
    }

    const stdout = std.io.getStdOut().writer();
    if (cfg.show_mean) {
        const avg = Compute.mean(numbers);
        try stdout.print("Mean {d:.3}\n", .{avg});
    }

    if (cfg.show_median) {
        const med = try Compute.median(alloc, numbers);
        try stdout.print("Median {d:.3}\n", .{med});
    }
}