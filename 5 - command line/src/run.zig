const std = @import("std");
const Config = @import("parser.zig").Config;

pub fn run(cfg: Config) !void {
    const out = std.io.getStdOut().writer();
    var i: u32 = 0;
    while (i < cfg.count) : (i += 1) {
        try out.print("Hello {s}!\n", .{cfg.name});
        if (cfg.verbose) {
            try out.print(" (iteration {}/{}.)\n", .{ i + 1, cfg.count });
        }
    }
}
