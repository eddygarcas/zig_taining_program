const std = @import("std");

const Config = @import("config.zig").Config;
const usage = @import("usage.zig");

pub fn parseArgs(args: [][:0]u8) !Config {
    var cfg = Config{};
    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--mean")) {
            cfg.show_mean = true;
        } else if (std.mem.eql(u8, arg, "--median")) {
            cfg.show_median = true;
        } else if (std.mem.eql(u8, arg, "--help")) {
            try usage.printUsage(args[0]);
            return error.ShowHelp;
        } else {
            try std.io.getStdErr().writer().print("Unknown flag {s}\n", .{arg});
            return error.Unkownflag;
        }
    }

    if (!cfg.show_mean and !cfg.show_median) {
        cfg.show_mean = true;
        cfg.show_median = true;
    }
    return cfg;
}
