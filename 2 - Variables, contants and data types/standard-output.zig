const std = @import("std");

/// This program demonstrates basic input/output operations in Zig
/// It reads a user's name from stdin and prints a greeting with their first letter
/// Uses buffer-based input reading and formatted output
pub fn main() !void {
    // Get handles for standard input/output
    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();

    while (true) {
        try stdout.print("What's your name? ",.{});
        
        // Define a fixed buffer for reading input
        var buffer: [1024]u8 = undefined;

        // Read input until newline character
        const result = try stdin.readUntilDelimiter(&buffer, '\n');
        // Print greeting with name and first character
        try stdout.print("Hello {s}! seems that you first letter is {u}",.{result,result[0]});
        break;
    }
}