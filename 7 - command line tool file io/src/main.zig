//! File I/O example demonstrating file operations and directory traversal
//! This module provides functionality to read configuration files and list directory contents
const std = @import("std");

/// Main entry point that demonstrates file operations
/// Opens and reads a config file, lists directory contents, and processes file lines
/// Uses page allocator for memory management
/// Returns error if file operations fail
pub fn main() !void {
    const alloc = std.heap.page_allocator;

    // Open file with read/write permissions
    const flags = std.fs.File.OpenFlags{ .mode = .read_write };
    const file = try std.fs.cwd().openFile("config.txt", flags);
    defer file.close();

    // List all files in current directory
    var iter = (try std.fs.cwd().openDir(".", .{ .iterate = true })).iterate();
    while (try iter.next()) |entry| {
        try std.io.getStdOut().writer().print("{s} -> {s}\n", .{ @tagName(entry.kind), entry.name });
    }

    // Read entire file content
    const content = try file.readToEndAlloc(alloc, 1024 * 10);
    defer alloc.free(content);
    try std.io.getStdOut().writer().print("{s}\n", .{content});

    // Process files line by line
    try readLines("config.txt");
    try readLines("configs.txt");
}

/// Reads and processes a file line by line
/// Handles file not found errors gracefully
/// Prints each line after trimming whitespace
/// Parameters:
///   path: File path to read
/// Returns: Error if file operations fail
fn readLines(path: []const u8) !void {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            try std.io.getStdOut().writer().print("No config file found.\n", .{});
            return;
        }
        return err;
    };
    defer file.close();

    var buffer_reader = std.io.bufferedReader(file.reader());
    var reader = buffer_reader.reader();

    var line_buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        const trimmed = std.mem.trim(u8, line, "\r\t");
        try std.io.getStdOut().writer().print("{s}\n", .{trimmed});
    }
}

test "run" {
    try main();
}