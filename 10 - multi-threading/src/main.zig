//! This is a simple demonstration of how to use Zig's threads and atomic
//! operations.
//!
//! The `counter` variable is shared between multiple threads and is protected
//! by a mutex so that only one thread can access it at a time.
//!
//! The `safeMap` struct is a simple wrapper around a `StringHashMap` that
//! provides thread-safe put and get operations using a mutex.
//!
//! The `main` function demonstrates how to create and manage threads, as well
//! as how to use atomic operations.
//!
//! The `addOne` function increments the `counter` variable using the mutex.
//!
//! The `worker` function demonstrates how to create a thread and execute a
//! function in that thread.
//!
//! The `sumRange` function demonstrates how to create a thread and calculate the
//! sum of a range of numbers.
//!
//! The `loopWorker` function demonstrates how to create a thread and continuously
//! loop until a value in an atomic variable changes.

const std = @import("std");

var counter: usize = 0;
var lock = std.Thread.Mutex{};

const safeMap = struct {
    map: std.StringHashMap(u32),
    mtx: std.Thread.Mutex = .{},

    /// Adds a key-value pair to the map.
    /// This function is thread-safe.
    pub fn put(self: *safeMap, key: []const u8, value: u32) !void {
        self.mtx.lock();
        defer self.mtx.unlock();
        self.map.put(key, value);
    }

    /// Retrieves a value from the map based on a key.
    /// This function is thread-safe.
    pub fn get(self: *safeMap, key: []const u8) ?u32 {
        self.mtx.lock();
        defer self.mtx.unlock();
        return self.map.get(key);
    }
};

pub fn main() !void {
    var t1 = std.Thread.spawn(.{}, worker, .{1}) catch |e| {
        if (e == error.SystemResources) {
            std.debug.print("Thread limit reached\n", .{});
            return;
        }
        return e;
    };

    var t2 = try std.Thread.spawn(.{}, worker, .{2});
    t1.join();
    t2.join();

    var answer: usize = 0;
    const th = try std.Thread.spawn(.{}, sumRange, .{ 1, 10, &answer });
    th.join();
    std.debug.print("Sum = {d}\n", .{answer});

    var t = try std.Thread.spawn(.{}, loopWorker, .{});
    std.time.sleep(2_000_000_000);
    running.store(false, .seq_cst);
    t.join();
}

/// Increments the `counter` variable using a mutex.
/// This function is thread-safe.
fn addOne() void {
    lock.lock();
    defer lock.unlock();
    counter += 1;
}

/// Executes a function in a new thread.
/// This function demonstrates how to execute a function in a new thread.
fn worker(id: usize) void {
    std.debug.print("Worker {d} running ... \n", .{id});
}

/// Calculates the sum of a range of numbers and stores the result in an output
/// variable.
/// This function demonstrates how to calculate a result in a new thread and
/// store the result in an output variable.
fn sumRange(start: usize, end: usize, result: *usize) void {
    var total: usize = 0;
    for (start..end + 1) |n| total += n;
    result.* = total;
}

var running = std.atomic.Value(bool).init(true);

/// Continuously loops until the value in the `running` atomic variable changes.
/// This function demonstrates how to use an atomic variable to control the
/// execution of a loop in a new thread.
fn loopWorker() void {
    while (running.load(.seq_cst)) {
        // do something
        std.debug.print("\rLooping ... {any}", .{std.time.nanoTimestamp()});
    }
}