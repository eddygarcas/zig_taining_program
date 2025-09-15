//! This is the main entry point for the CLI application.
//!
//! It parses the command line arguments and uses them to configure the formatter.
//! The formatter is then used to format the text provided on the command line. The
//! formatted text is then written to standard output.
const std = @import("std");
const fmt = @import("formatter.zig");

/// The main entry point for the CLI application.
///
/// It parses the command line arguments and uses them to configure the formatter.
/// The formatter is then used to format the text provided on the command line. The
/// formatted text is then written to standard output.
pub fn main() !void {
    const gpa = std.heap.page_allocator;
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    // Initialize the formatter options to default values.
    var opts = fmt.Options{};
    // Initialize a variable to hold the text to format.
    var text: ?[]const u8 = null;
    // Loop through the command line arguments.
    var i:usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        // If the argument is a width option, parse the width value and store it in the options.
        if (std.mem.startsWith(u8, arg, "--width=")) {
            opts.width = try std.fmt.parseInt(u8, arg["--width=".len..], 10);
        }
        // If the argument is an alignment option, parse the alignment value and store it in the options.
        else if (std.mem.startsWith(u8, arg, "--align=")) {
            opts.aligned = std.meta.stringToEnum(fmt.Align, arg["--align=".len..]) orelse return error.InvalidAlign;
        }
        // If the argument is a casing option, parse the casing value and store it in the options.
        else if (std.mem.startsWith(u8, arg, "--case=")){
            opts.casing = std.meta.stringToEnum(fmt.Casing, arg["--case=".len..]) orelse return error.InvalidCasing;
        }
        // If the argument starts with a '-' character and is not a valid option, return an error.
        else if (arg[0] == '-') {
            return error.UnknownFlag;
        }
        // If the argument is not a valid option, store it in the text variable.
        else {
            text = arg;
        }
    }
    // If no text was provided on the command line, return an error.
    if (text == null) return error.NoText;

    // Use the formatter to format the text and store the result in the out variable.
    const out = try fmt.format(text.?, opts, gpa);
    defer gpa.free(out);
    // Write the formatted text to standard output.
    try std.io.getStdOut().writeAll(out);
}