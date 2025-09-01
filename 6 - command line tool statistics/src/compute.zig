const std = @import("std");

/// Calculates the arithmetic mean of a slice of floating-point numbers
/// Arguments:
///   values: A slice of f64 numbers to calculate the mean of
/// Returns: The arithmetic mean as an f64
pub fn mean(values: []const f64) f64 {
    var sum: f64 = 0;
    for (values) |v| sum += v;
    const len: f64 = @floatFromInt(values.len);
    return sum / len;
}

/// Calculates the median value from a slice of floating-point numbers
/// Makes a copy of the input slice and sorts it to find the middle value(s)
/// Arguments:
///   alloc: Memory allocator for creating a temporary sorted copy
///   input: A slice of f64 numbers to calculate the median of
/// Returns: The median value as an f64, or an error if allocation fails
pub fn median(alloc: std.mem.Allocator, input: []const f64) !f64 {
    const copy = try alloc.alloc(f64, input.len);
    defer alloc.free(copy);

    @memcpy(copy, input);
    std.sort.insertion(f64, copy, {}, std.sort.asc(f64));
    const mid = input.len / 2;
    if (input.len % 2 == 0) {
        return (copy[mid - 1] + copy[mid]) / 2.0;
    } else {
        return copy[mid];
    }
}
