//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const DynString = @import("strings/dynstring.zig").DynString;

const Environment = enum { development, staging, production };
const Mode = enum { show, set, reset };
const Config = struct {
    port: u16 = 8080,
    env: Environment = .development,
    enable_cache: bool = true,

    fn to_log(this: Config) void {
        std.debug.print("Port {d}, Env {s}, Cache {}", .{ this.port, @tagName(this.env), this.enable_cache });
    }
};
const CONFIG_INI = "start.ini";

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const cmd = parseCmd(args) catch |e| {
        try std.io.getStdErr().writer().print("Error {}\n", .{e});
        return;
    };

    var cfg_ptr: Config = try loadConfig(alloc);

    switch (cmd.mode) {
        .show => std.debug.print("{any}\n", .{cfg_ptr}),
        .reset => std.fs.cwd().deleteFile(CONFIG_INI) catch |e| {
            if (e != error.FileNotFound) return e;
        },
        .set => {
            if (std.mem.eql(u8, cmd.key, "port")) {
                cfg_ptr.port = try std.fmt.parseInt(u16, cmd.val, 10);
            } else if (std.mem.eql(u8, cmd.key, "env")) {
                cfg_ptr.env = try parseEnv(cmd.val);
            } else if (std.mem.eql(u8, cmd.key, "enable_cache")) {
                cfg_ptr.enable_cache = std.mem.eql(u8, cmd.val, "true");
            } else {
                return error.InvalidKey;
            }
            try saveConfig(cfg_ptr, alloc);
        },
    }

}

/// Parses command line arguments and returns a struct with the parsed command, key, and value.
///
/// This function takes an array of strings representing command line arguments and returns a
/// struct with the parsed command, key, and value. The valid commands are `--show`, `--reset`,
/// and `--set`. For the `--set` command, the key and value are separated by an equals sign.
///
/// Parameters:
/// - `args`: An array of strings representing command line arguments.
///
/// Returns:
/// - If the command line arguments are valid, a struct with the parsed command, key, and value.
/// - If the command line arguments are invalid, an error.
///
/// Errors:
/// - `error.NoCommand`: If there are no command line arguments.
/// - `error.NoKeyOrValue`: If the `--set` command is specified but there are not enough arguments.
/// - `error.InvalidFormat`: If the `--set` command is specified but the key and value are not separated by an equals sign.
fn parseCmd(args: [][:0]u8) !struct { mode: Mode, key: []const u8 = "", val: []const u8 = "" } {
    if (args.len < 2) return error.NoCommand;
    if (std.mem.eql(u8, args[1], "--show")) return .{ .mode = .show };
    if (std.mem.eql(u8, args[1], "--reset")) return .{ .mode = .reset };
    if (std.mem.eql(u8, args[1], "--set")) {
        if (args.len < 3) return error.NoKeyOrValue;
        // `indexOfScalar` returns the index of the first occurrence of a scalar value in a slice.
        // This function takes a slice and a scalar value and returns the index of the first occurrence
        // of the scalar value in the slice. If the scalar value is not found, it returns `null`.
        const eq = std.mem.indexOfScalar(u8, args[2], '=') orelse return error.InvalidFormat;
        return .{
            .mode = .set,
            .key = args[2][0..eq],
            .val = args[2][eq + 1 ..],
        };
    }
    return error.UnknownFlag;
}

///
/// Parameters:
/// - `slice`: The slice to search.
/// - `value`: The scalar value to search for.
///
/// Returns:
/// - The index of the first occurrence of the scalar value in the slice.
/// - `null` if the scalar value is not found.
/// Saves the configuration to a file
///
/// This function takes a `Config` struct and an `std.mem.Allocator` and saves the
/// configuration to a file. The file is saved in INI format. This function creates a
/// temporary file with the same name as the original file with the `.tmp` extension.
/// The content of the original file is then overwritten with the content of the
/// temporary file.
///
/// Parameters:
/// - `cfg`: The `Config` struct containing the configuration to save.
/// - `alloc`: The `std.mem.Allocator` to use for memory allocation.
///
/// Errors:
/// - `std.fs.File.createFile` can fail with `error.FileNotFound` or `error.AccessDenied`.
/// - `std.fs.File.rename` can fail with `error.FileNotFound`, `error.AccessDenied`, `error.FileExists`,
///   `error.FileBusy`, or `error.FileLocksConflict`.
///
/// Returns:
/// - `!void`: This function does not return anything.
pub fn saveConfig(cfg: Config, alloc: std.mem.Allocator) !void {
    // We could avoid +DynString+ definition but I've used it as an example of how to create OOP
    // classes in Zig and how to contain allocator and string creation in one place.
    const tmp: DynString = try DynString.init(alloc, "{s}.tmp", .{CONFIG_INI});
    defer tmp.deinit();
    { // We use a block because defer f.close() must happen before rename.
        const f = try std.fs.cwd().createFile(tmp.slice(), .{ .truncate = true });
        defer f.close();

        const w = f.writer();
        try w.print("port={}\n", .{cfg.port});
        try w.print("env={s}\n", .{@tagName(cfg.env)});
        try w.print("enable_cache={}\n", .{cfg.enable_cache});
    }
    try std.fs.cwd().rename(tmp.slice(), CONFIG_INI);
}

/// Opens and reads a file and creates a structure to represent its contents.
///
/// This function opens a file with the given `alloc` and reads its contents into a `[]const u8` buffer.
/// It then parses the buffer into a `std.StringHashMap([]const u8)` using the `parseIni` function.
/// The resulting map is then used to hydrate a `Config` struct using the `hydrate` function.
///
/// Parameters:
/// - `alloc`: The `std.mem.Allocator` to use for memory allocation.
///
/// Errors:
/// - `std.fs.File.openFile` can fail with `error.FileNotFound` or `error.AccessDenied`.
/// - `std.fs.File.readToEndAlloc` can fail with `error.FileTooBig` or `error.OutOfMemory`.
/// - `parseIni` can fail with `error.InvalidFormat`.
/// - `hydrate` can fail with `error.InvalidFormat`, `error.InvalidEnvironment`, or `error.InvalidValue`.
///
/// Returns:
/// - `Config`: The `Config` struct representing the contents of the file.
/// - `error`: If any of the underlying functions fail, this function will return the corresponding error.
fn loadConfig(alloc: std.mem.Allocator) !Config {
    // Open the file
    const file = std.fs.cwd().openFile(CONFIG_INI, .{}) catch |e| {
        if (e == error.FileNotFound) {
            // If the file is not found, return an empty Config struct
            return Config{};
        }
        return e;
    };
    defer file.close();
    // Read the file into a buffer
    const buff: []const u8 = try file.readToEndAlloc(alloc, 1024 * 16);
    defer alloc.free(buff);
    // Parse the buffer into a StringHashMap
    var map: std.StringHashMap([]const u8) = try parseIni(buff, alloc);
    defer map.deinit();
    // Hydrate the Config struct
    var cfg = Config{};
    hydrate(&cfg, map) catch |e| {
        return e;
    };
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
        //std.debug.print("key {s} = {s}\n", .{ key, value });
    }
    return map;
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
        cfg.*.port = try std.fmt.parseInt(u16, val, 10);
    }
    if (map.get("environment")) |val| {
        cfg.*.env = try parseEnv(val);
    }
    if (map.get("enable_cache")) |val| {
        cfg.*.enable_cache = std.mem.eql(u8, val, "true");
    }
}

/// Converts string to Environment enum using std.meta.stringToEnum
fn parseEnv(input: []const u8) !Environment {
    return std.meta.stringToEnum(Environment, input) orelse error.InvalidEnvironment;
}
