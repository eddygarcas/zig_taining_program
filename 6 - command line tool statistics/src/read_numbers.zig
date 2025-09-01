const std = @import("std");

/// Reads numbers from standard input and returns them as an array of f64
/// Allocates memory for the array using the provided allocator
/// Returns an error if invalid numbers are encountered
/// The caller owns the returned slice and must free it
pub fn readNumbers(alloc: std.mem.Allocator) ![]f64 {
    // Read all input from stdin into a buffer, limited to 64KB
    const buffer = try std.io.getStdIn().readToEndAlloc(alloc, 64 * 1024);
    // Free the input buffer when function returns
    defer alloc.free(buffer);

    // Create a dynamic array to store the parsed numbers
    var list = std.ArrayList(f64).init(alloc);
    // Free the list when function returns
    defer list.deinit();

    std.debug.print("Buffer {any}\n", .{buffer});
    // Split input on newlines, returns, and tabs
    var it = std.mem.tokenizeAny(u8, buffer, " \n\r\t");
    // Parse each token into a float and append to list
    while (it.next()) |token| {
        std.debug.print("Token {s}\n", .{token});
        const num = std.fmt.parseFloat(f64, token) catch |err| {
            return err;
        };
        try list.append(num);
    }
    // Convert list to owned slice that caller must free
    return try list.toOwnedSlice();
}
