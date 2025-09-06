//! File I/O example demonstrating file operations and directory traversal
//! This module provides functionality to read configuration files and list directory contents
//! Key features:
//! - File reading/writing with buffered I/O using std.fs.File
//! - Directory traversal with std.fs.Dir.iterate()
//! - Line-by-line file processing with std.io.bufferedReader
//! - File appending with std.fs.File.seekTo() and writer()
//! - Error handling for common file operations
//! - Atomic file writes using std.fs.Dir.rename()

const std = @import("std");

/// Environment represents different deployment environments
/// Used with std.meta.stringToEnum for string-to-enum conversion
const Environment = enum { development, staging, production };

/// Configuration struct with default values
/// Fields use primitive types from std.builtin
const Config = struct {
    port: u16 = 8080,
    env: Environment = .development,
    enable_cache: bool = true,

    fn toLog(this: Config) void {
        std.debug.print("Port {d} | env {s} | cache {}", .{ this.port, @tagName(this.env), this.enable_cache });
    }
};

/// Main entry point that demonstrates file operations using std.fs and std.io
/// Uses std.heap.page_allocator for memory management
/// Returns error if file operations fail
pub fn main() !void {
    const alloc = std.heap.page_allocator;

    // std.fs.File.OpenFlags controls file access mode
    const flags = std.fs.File.OpenFlags{ .mode = .read_write };
    const file = try std.fs.cwd().openFile("config.txt", flags);
    defer file.close();

    // std.fs.Dir.iterate() provides directory iteration
    var iter = (try std.fs.cwd().openDir(".", .{ .iterate = true })).iterate();
    while (try iter.next()) |entry| {
        try std.io.getStdOut().writer().print("{s} -> {s}\n", .{ @tagName(entry.kind), entry.name });
    }

    // std.fs.File.readToEndAlloc reads entire file into buffer
    const content = try file.readToEndAlloc(alloc, 1024 * 10);
    defer alloc.free(content);
    try std.io.getStdOut().writer().print("{s}\n", .{content});

    try readLines("configs.txt");
    try appendToFile("config.txt", "\nAppend text to a file\n");
    try readLines("config.txt");
    try writeAtomic("config.txt", "test", alloc);

    const env = try parseEnv("development");
    std.debug.print("Environment {s}\n", .{@tagName(env)});
    _ = parseEnv("devel") catch |err| {
        std.debug.print("Bad environment {s}\n", .{@errorName(err)});
    };

    // Read INI file content into memory using temporary allocation
    const content_ini = try readContentFromFile("start.ini", alloc);
    defer alloc.free(content_ini); // Memory cleanup pattern in Zig

    // Parse content into hashmap using std.StringHashMap - Zig's built-in hash table
    const map: std.StringHashMap([]const u8) = try parseIni(content_ini, alloc);

    // Iterate through hashmap using iterator() - Zig's safe iteration pattern
    var iterHash = map.iterator();
    while (iterHash.next()) |elem| {
        // Access pointers using .* operator - explicit pointer dereferencing in Zig
        std.debug.print("map[{s}] = {s}\n", .{ elem.key_ptr.*, elem.value_ptr.* });
    }

    var cfg: Config = Config{};
    hydrate(&cfg, map) catch |err| {
        std.debug.print("Error hydrate map {}", .{err});
    };
    cfg.toLog();

    const json_cfg = try std.fs.cwd().openFile("start.json", .{});
    defer json_cfg.close();
    const content_json = try json_cfg.readToEndAlloc(alloc, 1024 * 64);
    defer alloc.free(content_json);
    const cfgIni: Config = try parseJson(content_json, alloc);
    cfgIni.toLog();
}

/// Hydrates a Config struct with values from a string hash map
/// Takes a pointer to Config and a StringHashMap of string values
/// Performs type conversion for each field:
/// - port: string to u16 integer
/// - environment: string to Environment enum
/// - enable_cache: string comparison to bool
/// Returns error if parsing fails
fn hydrate(cfg: *Config, map: std.StringHashMap([]const u8)) !void {
    if (map.get("port")) |val| {
        cfg.port = try std.fmt.parseInt(u16, val, 10);
    }
    if (map.get("environment")) |val| {
        cfg.env = try parseEnv(val);
    }
    if (map.get("enable_cache")) |val| {
        cfg.enable_cache = std.mem.eql(u8, val, "true");
    }
}

/// Parses JSON content into a Config struct
/// Uses std.json.Parsed and std.json.Value to parse JSON into a struct
/// Returns Config struct with parsed values
/// @param content: JSON content to parse
/// @param alloc: Memory allocator for dynamic allocations
/// @return Config struct with parsed values or error
fn parseJson(content: []const u8, alloc: std.mem.Allocator) !Config {
    // Parse JSON content into a Parsed struct using std.json.parseFromSlice
    // The Parsed struct is an intermediate representation of JSON data
    var tree: std.json.Parsed(std.json.Value) = try std.json.parseFromSlice(std.json.Value, alloc, content, .{});
    defer tree.deinit();

    // Create an empty Config struct
    var cfg = Config{};

    // Extract the JSON object from Parsed struct
    const obj = tree.value.object;

    // Parse port value from JSON object
    if (obj.get("port")) |val| {
        // Convert JSON integer to u16 integer
        cfg.port = @intCast(val.integer);
    }

    // Parse environment value from JSON object
    if (obj.get("environment")) |val| {
        // Convert JSON string to Environment enum
        cfg.env = try parseEnv(val.string);
    }

    // Parse enable_cache value from JSON object
    if (obj.get("enable_cache")) |val| {
        // Convert JSON boolean to bool
        cfg.enable_cache = val.bool;
    }

    // Return the parsed Config struct
    return cfg;
}

/// Parses INI file content into std.StringHashMap
/// Uses std.mem.tokenizeAny for line splitting
fn parseIni(content: []const u8, alloc: std.mem.Allocator) !std.StringHashMap([]const u8) {
    // Notice that the defer command is here, doing it inside *readContnentFromFile()* will raise a
    // compilation error
    var map = std.StringHashMap([]const u8).init(alloc);
    var lines = std.mem.tokenizeAny(u8, content, "\n");
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, "\t\r");
        if (line.len == 0 or line[0] == '#') continue;

        const eq = std.mem.indexOfScalar(u8, line, '=') orelse return error.InvalidFormat;
        const key = std.mem.trim(u8, line[0..eq], "\t");
        const value = std.mem.trim(u8, line[eq + 1 ..], "\t");

        // Important! if you want to actually store key/value in the map you have to copy them into a new
        // memory allocation other wise when defer alloc.free(content) they will be lost.
        //try map.put(try alloc.dupe(u8, key), try alloc.dupe(u8, value));

        // If you choose to use the content of *content* parameter then the defer alloc.free(contect) has to
        // be place before this call.
        try map.put(key, value);
        std.debug.print("key {s} = {s}\n", .{ key, value });
    }
    return map;
}

/// Converts string to Environment enum using std.meta.stringToEnum
fn parseEnv(input: []const u8) !Environment {
    return std.meta.stringToEnum(Environment, input) orelse error.InvalidEnvironment;
}

/// Reads file content using std.fs.File.readToEndAlloc
fn readContentFromFile(path: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(alloc, 1024 * 10);
}

/// Performs atomic file write using std.fs.Dir.rename
fn writeAtomic(path: []const u8, text: []const u8, alloc: std.mem.Allocator) !void {
    const cwd = std.fs.cwd();
    const temp_file = try std.fmt.allocPrint(alloc, "{s}.tmp", .{path});
    defer alloc.free(temp_file);
    {
        const file = try cwd.createFile(temp_file, .{ .truncate = true });
        defer file.close();
        try file.writer().writeAll(text);
    }
    try cwd.rename(temp_file, path);
}

/// Appends text using std.fs.File.seekTo and writer
fn appendToFile(path: []const u8, text: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_write });
    defer file.close();
    try file.seekTo(try file.getEndPos());
    try file.writer().writeAll(text);
}

/// Reads file line-by-line using std.io.bufferedReader
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
