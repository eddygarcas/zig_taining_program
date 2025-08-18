const std = @import("std");

pub fn main() !void {
    const maxIterations: i32 = 10;
    var counter: i32 = 0;

    // If a variable is declared it needs to change at some point in the code otherwise
    // the compiler will give you an error recomending to use const instead.
    var ptr_to_maxIterations: *const i32 = undefined;
    ptr_to_maxIterations = &maxIterations;
    while (counter < maxIterations) : (counter += 1) {
        std.debug.print("Counter: {d}\n", .{counter});
    }

    std.debug.print("maxIterations: {d}\n", .{ptr_to_maxIterations.*});
}
