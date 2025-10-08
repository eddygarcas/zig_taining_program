const std = @import("std");
const c = @cImport({
    @cInclude("math.h");
    @cInclude("stdlib.h");
    @cInclude("stdio.h");
    @cInclude("vector.h");
});

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    const v = 3.14159265;
    const s = c.sin(v);
    const n = c.sqrt(2.0);

    std.debug.print("sin={d:.6}\n", .{s});
    std.debug.print("sqrt={d:.6}\n", .{n});

    const path = "/usr/bin";
    _ = c.puts(path);

    const ve = c.vec3{
        .x = 1.0,
        .y = 2.0,
        .z = 3.0,
    };
    const len = c.vec_lenght(ve);
    std.debug.print("len={d:.6}\n", .{len});
}
