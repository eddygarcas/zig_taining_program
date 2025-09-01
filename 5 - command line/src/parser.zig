const std = @import("std");

pub const Config = struct {
    count: u32 = 1,
    verbose: bool = false,
    name: []const u8 = "main",
};

const Error = error{
    MissingCount,
    MissingName,
    UnknownFlag,
};
//alloc: ?std.mem.Allocator, 
pub fn parseArgs(args: [][:0]u8) !Config {
    var cfg = Config{};
    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--count")) {
            i += 1;
            if (i >= args.len) return Error.MissingCount;
            cfg.count = try std.fmt.parseInt(u32, args[i], 10);
        } else if (std.mem.eql(u8, arg, "--verbose")) {
            cfg.verbose = true;
        } else if (std.mem.eql(u8, arg, "--name")) {
            i += 1;
            if (i >= args.len) return Error.MissingName;
            cfg.name = args[i];
        } else {
            return Error.UnknownFlag;
        }
    }
    return cfg;
}