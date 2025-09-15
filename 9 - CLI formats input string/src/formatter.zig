/// The module provides a simple formatter for strings. The formatter
/// supports adjusting the string width, changing the case of the string,
/// and aligning the string to the left, right, or center.
const std = @import("std");

/// The alignment of the string.
pub const Align = enum { left, right, center };

/// The casing of the string.
pub const Casing = enum { none, lower, upper, title };

/// The options for the formatter.
pub const Options = struct {
    /// The width of the output string.
    width: usize = 0,

    /// The alignment of the output string.
    aligned: Align = .left,

    /// The casing of the output string.
    casing: Casing = .none,
};

/// Formats the input string according to the provided options.
///
/// Parameters:
/// - input: The input string to format.
/// - opts: The options for formatting the string.
/// - alloc: The allocator used to allocate memory for the output string.
///
/// Returns:
/// - The formatted string.
pub fn format(input: []const u8, opts: Options, alloc: std.mem.Allocator) ![]u8 {
    const buf = try alloc.alloc(u8, input.len);
    std.mem.copyForwards(u8, buf, input);

    switch (opts.casing) {
        .upper => {
            for (buf) |*c| c.* = std.ascii.toUpper(c.*);
        },
        .lower => {
            for (buf) |*c| c.* = std.ascii.toLower(c.*);
        },
        .title => {
            titleCase(buf);
        },
        .none => {},
    }

    if (opts.width == 0 or opts.width == buf.len) return buf;
    if (opts.width < buf.len) return buf[0..opts.width];

    const pad_total = opts.width - buf.len;
    const left_pad = switch (opts.aligned) {
        .left => 0,
        .right => pad_total,
        .center => pad_total / 2,
    };

    const right_pad = pad_total - left_pad;

    // Create a mutable output buffer using the size of the opts.width defined.
    // later will fill this slice based on the opts specification.
    var out = try alloc.alloc(u8, opts.width);
    // Fill the left padding with spaces
    @memset(out[0..left_pad], ' ');
    // Copy the input string to the output string
    @memcpy(out[left_pad .. left_pad + buf.len], buf);
    // Fill the right padding with spaces
    @memset(out[out.len - right_pad ..], ' ');
    alloc.free(buf);

    return out;
}

/// Converts the first character of each word in the input string to uppercase.
///
/// Parameters:
/// - input: The input string to convert.
fn titleCase(input: []u8) void {
    var cap = true;
    for (input) |*c| {
        const ch = c.*;
        c.* = if (cap) std.ascii.toUpper(ch) else std.ascii.toLower(ch);
        cap = ch == ' ';
    }
}

// test ----

test "center align with width 10" {
    const opts = Options{
        .witdh = 10,
        .aligned = .center,
    };
    const out = try format("zig", opts, std.testing.allocator);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("   zig    ", out);
}

test "upper-case no width" {
    const opts = Options{ .casing = .upper };
    const out = try format("hello", opts, std.testing.allocator);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings(out, "HELLO");
}