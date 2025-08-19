const std = @import("std");

pub fn main() !void {
    // Tuples in Zig are anonymous structs with numbered fields
    const myTuple = .{
        42,
        "Hello", 
        3.14,
    };

    const intValue: i32 = myTuple[0];
    // In Zig strings are arrays of bytes (u8)
    const stringValue: []const u8 = myTuple[1];
    const floatValue: f32 = myTuple[2];

    std.debug.print("intValue: {d}\n", .{intValue});
    std.debug.print("stringValue: {s}\n", .{stringValue});
    // Format floats with decimal precision using {d:.2}
    std.debug.print("floatValue: {d:.2}\n", .{floatValue});

    // Print entire tuple with matched format specifiers
    std.debug.print("My tuple decimal {d} string {s} and float {d:.2}\n", myTuple);

    // enum: A type that can only have one of a fixed set of values
    // Here Race can only be either dog or cat
    const Race = enum {
        dog,
        cat,
    };

    // Tagged union: Combines an enum with data for each variant
    // Each variant can hold different types of data
    // Here Pet uses Race as its tag and holds string data for each variant
    const Pet = union(Race) {
        dog: []const u8,
        cat: []const u8,

        fn get(self: @This()) !void {
            return switch (self) {
                .dog => |d| std.debug.print("is a dog and it is a {s}\n", .{d}),
                .cat => |c| std.debug.print("is a cat and it is a {s}\n", .{c}),
            };
        }
    };

    // struct: A composite type that groups together named fields
    // Here MyPet combines a name string with a Pet tagged union
    // Also defines values by default.
    const MyPet = struct {
        name: []const u8 = "Joy",
        race: Pet = Pet{ .dog = "Border Collie" },
    };

    const myPet = MyPet{};

    std.debug.print("My pet name is {s} and ", .{myPet.name});
    // Using catch to handle potential errors from get():
    // 1. _ = discards the success value since get() returns void
    // 2. catch captures any error in err variable
    // 3. If error occurs, prints it using debug.print
    _ = myPet.race.get() catch |err| std.debug.print("error: {s}\n", .{err});
}