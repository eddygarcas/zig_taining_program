const std = @import("std");

/// This program demonstrates array operations and testing in Zig
/// Shows how to:
/// - Define and iterate over arrays
/// - Use array slicing
/// - Incorporate inline tests to validate types
pub fn main() !void {
    const myArray: []const i32 = &.{ 10, 20, 30, 40, 50, 60, 70, 80, 90 };
    std.debug.print("Array values {any}", .{myArray});

    // Iterate through array slice while testing index type
    for (myArray[0..2], 0..) |item, index| {
        std.testing.expect(@TypeOf(index) == usize) catch |err| {
            // Here will print the error but continue the execution
            // replace *catch* for *try* and it will raise up the error
            std.debug.print("Index is not a usize {any}\n", .{err});
        };
        std.debug.print("Element at index {} is {d} \n", .{ index, item });
    }
}

test "verify index type in array iteration" {
    //var index: usize = 0;
    //try std.testing.expect(@TypeOf(index) == usize);
}