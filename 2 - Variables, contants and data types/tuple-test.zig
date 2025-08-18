const std = @import("std");

pub fn main() !void {
    const myTuple = .{
        42,
        "Hello",
        3.14,
    };

    const intValue: i32 = myTuple[0];
    // In Zig string are a []const u8
    const stringValue: []const u8 = myTuple[1];
    const floatValue: f32 = myTuple[2];

    std.debug.print("intValue: {d}\n", .{intValue});
    std.debug.print("stringValue: {s}\n", .{stringValue});
    // for floats you can use the format decimal and precision
    std.debug.print("floatValue: {d:.2}\n", .{floatValue});

    // You can print the whole tuple directly but it will access it in order, so make sure
    // the format matches the order in the tuple.
    std.debug.print("My tuple decimal {d} string {s} and float {d:.2}\n", myTuple);

    // Here you define a Tagged union to define all types of pets and deifine its race.
    // This kind of union is called tagged union and allows to define method to get the type.
    const Race = enum {
        dog,
        cat,
    };

    const Pet = union(Race) {
        dog: []const u8,
        cat: []const u8,

        // Rather than return the pet race, we could just print the whole information if the method also gets the name.
        fn get(self: @This(), name: []const u8) !void {
            return switch (self) {
                .dog => |d| std.debug.print("My dog name is {s} and it is a {s}\n", .{ name, d }),
                .cat => |c| std.debug.print("My cat name is {s} and it is a {s}\n", .{ name, c }),
            };
        }
    };

    // Here we define a tuple to name our pet as well as define a Pet tagged union saying that a Border Collie dog
    const MyPet = .{
        "Joy",
        Pet{ .dog = "Border Collie" },
    };

    // Tagged unions allows us to using the same method return different values, in this case
    // all of them are []const u8 but we could return other types just playing with the definition.
    _ = try MyPet[1].get(MyPet[0]);
}
