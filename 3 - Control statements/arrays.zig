const std = @import("std");

/// This program demonstrates array operations and testing in Zig
/// Shows how to:
/// - Define and iterate over arrays
/// - Use array slicing
/// - Incorporate inline tests to validate types
/// - Test array element types
/// - Demonstrate mutable vs immutable slices
/// - Show array iteration with indexes
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

    const myString: []const u8 = &.{'d','u','a','r','k','o','v'};
    for (myString,0..) |item,index| {
        std.testing.expect(@TypeOf(item) == u8) catch |err| {
            std.debug.print("Item {u} at {d} is not a character {any}",.{item,index,err});
        };
        std.debug.print("{c}", .{item});
    }

    const myNums: [5]i32 = .{1,2,3,4,5};
    const mySlice : []const i32 = myNums[1..4];

    for (mySlice,0..) |item,index| {
        std.debug.print("The number at {d} is {d}\n", .{item,index});
    }

    var myNumsMutex: [5]i32 = .{1,2,3,4,5};
    var mySliceMutex: []i32 = myNumsMutex[1..4];

    mySliceMutex[0]=25;
    for (mySliceMutex) |item| {
        std.debug.print("Number {d}\n",.{item});
    }
}

test "verify index type in array iteration" {
    //var index: usize = 0;
    //try std.testing.expect(@TypeOf(index) == usize);
}