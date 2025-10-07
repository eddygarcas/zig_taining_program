/// Main entry point of the program.
const std = @import("std");

const PackedStruct = packed struct { a: u8, b: u16 };

const myStruct = struct { a: u16, b: u32 };

const Arena = struct {
    buf: []u8,
    top: usize = 0,
    fn init(storage: []u8) Arena {
        return .{ .buf = storage };
    }
    fn alloc(self: *Arena, len: usize, ali: u29) ![]u8 {
        const start = std.mem.alignForward(usize, self.top, ali);
        const end = start + len;
        if (end > self.buf.len) return error.OutOfMemory;
        self.top = end;
        return self.buf[start..end];
    }
    fn reset(self: *Arena) void {
        self.top = 0;
    }
};

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    var buff: [10]u8 = undefined;
    // Slices the buffer from index 2 to 8.
    var view: []u8 = buff[2..8];
    // Sets the first element of the slice to 42.
    view[0] = 42;

    // A raw pointer to the buffer at index 4.
    const raw_ptr: *u8 = &buff[4];
    // Sets the value of the raw pointer to 99.
    raw_ptr.* = 99;
    // Prints the value of the raw pointer to stderr.
    std.debug.print("Raw pointer value {d}\n", .{raw_ptr.*});
    // Demonstrates the use of memory layout and alignment control:
    // - `@sizeOf(T)` returns the byte size of a type.
    // - `@alignOf(T)` returns its required alignment.
    // - `@fieldParentPtr()` reconstructs the parent struct from a field pointer.
    //Memory Layout and Alignment Zig provides built-in introspection for layout control:
    // ● @sizeOf(T) returns the byte size of a type.
    // ● @alignOf(T) returns its required alignment.
    // ● @fieldParentPtr() reconstructs the parent struct from a field pointer.
    const mem = [_]u8{ 0xaa, 0xbb, 0xcc, 0xdd };
    // A pointer to the first element of the mem array.
    const ptr: *const u32 = @ptrCast(@alignCast(&mem[0]));
    // The value of the pointer.
    const value = ptr.*;
    // Prints the value of the pointer to stderr.
    std.debug.print("Pointer {d}\n", .{value});
    // Calls the demo function.
    demo();

    // Now we are going to implement a Build a Hex Dumper with Manual Memory Control
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) return error.BadUsage;

    var storage: [64 * 1024]u8 = undefined;
    var arena = Arena.init(&storage);

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    const size = try file.getEndPos();
    const buf = try arena.alloc(size, @alignOf(u8));
    _ = try file.readAll(buf);
    try dump(buf);
}

fn dump(buf: []const u8) !void {
    var line: [128]u8 = undefined;

    var offset: usize = 0;
    while (offset < buf.len) : (offset += 16) {
        const chunk = buf[offset..@min(offset + 16, buf.len)];

        var ascii: [16]u8 = undefined;
        for (chunk, 0..) |byte, i| {
            ascii[i] = if (std.ascii.isPrint(byte)) byte else '.';
        }

        const written = try std.fmt.bufPrint(&line, "{x:0>8} {s: <48} |{s:<16}|\n", .{ offset, chunk, ascii[0..chunk.len] });
        try std.fs.File.stdout().writeAll(written);
    }
}

fn fmtHex(bytes: []const u8) [48]u8 {
    var out: [48]u8 = undefined; // 16 * 3 (two hex + space)
    @memset(u8, &out);
    for (bytes, 0..) |b, i| {
        const hex = std.fmt.bytesToHex(b, .{});
        out[i * 3] = hex[0];
        out[i * 3 + 1] = hex[1];
    }
    return out;
}

/// A function that demonstrates more memory layout and alignment control.
//comptime {
//    std.debug.assert(@sizeOf(PackedStruct) == 3);
//    std.debug.assert(@alignOf(PackedStruct) == 1);
//}
pub fn demo() void {
    // A struct with two fields.
    var data = myStruct{ .a = 10, .b = 42 };

    // A pointer to the first field of the struct.
    const base: *u16 = @ptrCast(&data);
    // Prints the value of the base pointer to stderr.
    std.debug.print("Base value {d}\n", .{base.*});
    // A pointer to the second field of the struct.
    const b_ptr = &data.a;
    // A pointer to the second field, cast to a pointer to a u16.
    const b_offset: *u16 = @ptrCast(b_ptr);
    // Prints the offset of the second field to stderr.
    std.debug.print("Offset of b is {}\n", .{base.* - b_offset.*});
}
