const std = @import("std");
const print = std.debug.print;
const parser = @import("parser.zig");
const run = @import("run.zig");
const usage = @import("usage.zig");
usingnamespace std;
usingnamespace parser;
usingnamespace usage;
usingnamespace run;

/// Main entry point for the command-line application
/// Handles argument parsing, help display, and program execution
/// Uses page allocator for argument handling and frees memory on exit
/// Returns error on invalid arguments or execution failure
pub fn main() !void {
    print("This is the main function {s}\n",.{"codebase"});
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator,args);

    if (args.len > 1 and std.mem.eql(u8, args[1],"--help")) {
        try usage.printUsage(args[0]);
        return;
    }

    const cfg = parser.parseArgs(args) catch |err| {
        try usage.printUsage(args[0]);
        std.debug.print("Error {}\n", .{err});
        return;
    };
    print("Number of CPUs {any}\n",.{std.os.linux.cpu_count_t});

    try run.run(cfg);
}