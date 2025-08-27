const std = @import("std");

/// Inline functions in Zig are evaluated at compile-time rather than runtime
/// The 'inline' keyword tells the compiler to embed the function's code directly
/// where it's called, potentially improving performance by avoiding function call overhead
/// This is particularly useful for small, frequently called functions
inline fn square(x: i32) i32 {
    return x * x;
}

inline fn addOne(x: i32) i32 {
    return x + 1;
}

pub fn main() void {
    const result = square(5);
    std.debug.print("The square is {}\n", .{result});
    var count: i32 = 0;
    while (count < 5) : (count = addOne(count)) {
        std.debug.print("{}", .{count});
    }
}
