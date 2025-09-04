//! File I/O example demonstrating file operations and directory traversal
//! This module provides functionality to read configuration files and list directory contents
//! Key features:
//! - File reading/writing with buffered I/O
//! - Directory traversal and file listing
//! - Line-by-line file processing
//! - File appending operations
//! - Error handling for common file operations

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

    // List all files in current directory with their types
    var iter = (try std.fs.cwd().openDir(".", .{ .iterate = true })).iterate();
    while (try iter.next()) |entry| {
        try std.io.getStdOut().writer().print("{s} -> {s}\n", .{ @tagName(entry.kind), entry.name });
    }

    // Read entire file content into memory with size limit
    const content = try file.readToEndAlloc(alloc, 1024 * 10);
    defer alloc.free(content);
    try std.io.getStdOut().writer().print("{s}\n", .{content});

    // Process files line by line
    try readLines("configs.txt");

    // Append new text to existing file
    try appendToFile("config.txt", "\nAppend text to a file\n");
    try readLines("config.txt");
}

/// Appends text to the end of a file
/// Opens file in read/write mode, seeks to end, and writes new content
/// Parameters:
///   path: File path to append to
///   text: Text content to append
/// Returns: Error if file operations fail
fn appendToFile(path: []const u8, text: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_write });
    defer file.close();
    const end = try file.getEndPos();
    try file.seekTo(end);
    try file.writer().writeAll(text);
}

/// Reads and processes a file line by line
/// Uses buffered reader for efficient I/O
/// Handles file not found errors gracefully
/// Trims whitespace from each line before printing
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