//! A dynamic string type that can be used to store and manipulate strings in
//! memory.
//!
//! This module provides a `Dynstring` type that can be used to store and
//! manipulate strings in memory. The `Dynstring` type is a struct that contains
//! two fields: `buf`, which is a dynamic array of `u8` that stores the string,
//! and `alloc`, which is an `std.mem.Allocator` used for memory allocation.

const std = @import("std");

/// A dynamic string type that can be used to store and manipulate strings in
/// memory.
///
/// The `Dynstring` type is a struct that contains two fields: `buf`, which is a
/// dynamic array of `u8` that stores the string, and `alloc`, which is an
/// `std.mem.Allocator` used for memory allocation.
pub const DynString = struct {
    /// The dynamic array of `u8` that stores the string.
    buf: []u8,

    /// The `std.mem.Allocator` used for memory allocation.
    alloc: std.mem.Allocator,

    /// Initializes a new `Dynstring` with the given format string and arguments.
    ///
    /// This function takes an `std.mem.Allocator`, a format string, and any number
    /// of arguments. It uses the `std.fmt.allocPrint` function to format the
    /// arguments according to the format string and allocates memory to store the
    /// resulting string. The resulting `Dynstring` is then returned.
    ///
    /// Parameters:
    /// - `alloc`: The `std.mem.Allocator` used for memory allocation.
    /// - `fmt`: The format string.
    /// - `args`: The arguments to be formatted.
    ///
    /// Returns:
    /// - `Dynstring`: A new `Dynstring` with the formatted string.
    pub fn init(alloc: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !DynString {
        return DynString{
            .buf = try std.fmt.allocPrint(alloc, fmt, args),
            .alloc = alloc,
        };
    }

    /// Deinitializes a `Dynstring` and frees the memory allocated for it.
    ///
    /// This function takes a `Dynstring` and frees the memory allocated for it.
    /// The `alloc` field of the `Dynstring` is used to free the memory.
    ///
    /// Parameters:
    /// - `self`: The `Dynstring` to be deinitialized.
    pub fn deinit(self: DynString) void {
        self.alloc.free(self.buf);
        // Not heap allocated
        //self.alloc.destroy(self);
        // rather Stack allocated
        //self.* = undefined;
    }

    /// Returns a slice of the string stored in the `Dynstring`.
    ///
    /// This function takes a `Dynstring` and returns a slice of the string stored
    /// in the `Dynstring`.
    ///
    /// Parameters:
    /// - `this`: The `Dynstring` to get the string from.
    ///
    /// Returns:
    /// - `[]const u8`: A slice of the string stored in the `Dynstring`.
    pub fn slice(this: DynString) []const u8 {
        return this.buf;
    }
};