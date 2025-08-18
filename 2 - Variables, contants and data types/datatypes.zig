const std = @import("std");

pub fn main() !void {
    var myInt: i32 = undefined;
    myInt = 42;
    const myUnsignedInt: u64 = 12345678901234;

    std.debug.print("myInt: {d}\n", .{myInt});
    std.debug.print("myUnsignedInt: {d}\n", .{myUnsignedInt});

    myInt = 100;
    std.debug.print("myInt: {d}\n", .{myInt});

    if (myInt >= 100) {
        std.debug.print("myInt is greater than 100\n", .{});
    }
}
