const std = @import("std");

/// This program demonstrates basic comparison operators in Zig
/// Shows examples of equality, inequality, division and logical operators
/// Uses stdout for printing results and error handling with catch
pub fn main() void {
    // Initialize constant integer values
    const a: i32 = 10;
    const b: i32 = 20; 
    const c: i32 = 1;

    // Get a writer for stdout
    const stdout = std.io.getStdOut().writer();

    // Basic comparison operations with error handling
    stdout.print("a == b : {}\n", .{a == b}) catch {};
    stdout.print("a != b : {}\n", .{a != b}) catch {};
    stdout.print("a / b : {}\n", .{a / c}) catch {};

    // Logical OR operation combining equality and greater-than-or-equal
    const orResult: bool = ((a == b) or (a >= b));
    stdout.print("Or result {}\n", .{orResult}) catch |err| {
        std.debug.print("Error {}", .{err});
    };

    // Logical AND operation combining equality and greater-than-or-equal
    const andResult: bool = ((a == b) and (a >= b));
    stdout.print("And result {}\n", .{andResult}) catch |err| {
        std.debug.print("Error {}", .{err});
    };
}