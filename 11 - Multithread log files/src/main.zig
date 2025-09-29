//! This Zig program demonstrates how to implement a thread-safe queue of messages.
//! The queue is used to handle log messages and is accessed by multiple threads.
const std = @import("std");
const builtin = @import("builtin");

/// Define a buffer capacity for the queue.
const CAPCITY = 1024;

/// Define a struct to represent log messages.
const Msg = struct {
    /// The timestamp of the message.
    timestamp: i64,
    /// The ID of the thread that generated the message.
    thread_id: u32,
    /// The text of the message.
    text: [64]u8,
};

/// Define a struct to represent the queue of messages.
const Queue = struct {
    /// The buffer to hold the messages.
    buf: [CAPCITY]Msg = undefined,
    /// The index of the head of the queue.
    head: usize = 0,
    /// The index of the tail of the queue.
    tail: usize = 0,
    /// The mutex used to protect access to the queue.
    mtx: std.Thread.Mutex = .{},

    /// Push a message onto the queue.
    ///
    /// Parameters:
    /// - `q`: A pointer to the queue.
    /// - `m`: The message to push onto the queue.
    ///
    /// Returns:
    /// - `true` if the message was successfully pushed onto the queue.
    /// - `false` if the queue is full.
    pub fn push(q: *Queue, m: Msg) bool {
        // Lock the mutex to protect access to the queue.
        q.mtx.lock();
        defer q.mtx.unlock();

        // Check if the queue is full.
        if ((q.tail + 1) & (CAPCITY - 1) == q.head) return false;

        // Push the message onto the queue.
        q.buf[q.tail] = m;
        q.tail = (q.tail + 1) & (CAPCITY - 1);
        return true;
    }

    /// Pop a message from the queue.
    ///
    /// Parameters:
    /// - `q`: A pointer to the queue.
    ///
    /// Returns:
    /// - The message at the head of the queue.
    /// - `null` if the queue is empty.
    pub fn pop(q: *Queue) ?Msg {
        // Lock the mutex to protect access to the queue.
        q.mtx.lock();
        defer q.mtx.unlock();

        // Check if the queue is empty.
        if (q.head == q.tail) return null;

        // Pop the message from the queue.
        const out = q.buf[q.head];
        q.head = (q.head + 1) & (CAPCITY - 1);
        return out;
    }
};

/// The main function.
/// The main function.
///
/// This function sets up a logging system that uses multiple threads to write messages to a file.
/// It creates a file named "logsafe.txt" and initializes a queue and a boolean flag to control the logging process.
/// It then spawns a logger thread that continuously pops messages from the queue and writes them to the file.
/// It creates four worker threads that generate messages and push them onto the queue.
/// After all the work is done, it signals the logger thread to stop by setting the done flag to true.
/// Finally, it waits for all the threads to finish and prints a message indicating that the log has been written.
pub fn main() !void {
    // Create a file named "logsafe.txt" and open it for writing.
    var log_file = try std.fs.cwd().createFile("logsafe.txt", .{ .truncate = true });
    defer log_file.close(); // Close the file when the function returns.
    // Initialize a queue to hold the messages and a boolean flag to control the logging process.
    var queue = Queue{};
    var done = false;
    // Spawn a logger thread that continuously pops messages from the queue and writes them to the file.
    var logger = try std.Thread.spawn(.{}, loggerThread, .{ &queue, &done, &log_file });
    // Create four worker threads that generate messages and push them onto the queue.
    const THREADS: usize = 4;
    var workers: [THREADS]std.Thread = undefined;
    for (&workers, 0..) |*work, idx| {
        const index: u32 = @intCast(idx);
        work.* = try std.Thread.spawn(.{}, worker, .{ index, &queue });
    }
    // Wait for all the worker threads to finish.
    for (workers) |t| t.join();
    // Signal the logger thread to stop by setting the done flag to true.
    done = true;
    // Wait for the logger thread to finish.
    logger.join();
    // Print a message indicating that the log has been written.
    std.debug.print("Log written to logsafe.txt\n", .{});
}

/// This function represents a thread that writes messages from a queue to a file.
///
/// Parameters:
/// - `q`: A pointer to the queue.
/// - `done`: A pointer to a boolean variable that indicates whether the thread should stop.
/// - `file`: A pointer to the file where the messages will be written.
fn loggerThread(q: *Queue, done: *bool, file: *std.fs.File) !void {
    while (true) {
        // Pop a message from the queue.
        if (q.pop()) |msg| {
            // Write the message to the file.
            var buf: [64]u8 = undefined;
            var buf_writer = file.writer(&buf);
            const buf_stdout = &buf_writer.interface;

            try buf_stdout.print("[{d} (T{d}) {s}\n", .{ msg.timestamp, msg.thread_id, msg.text });
            // If the queue is empty and the done flag is set, stop the thread.
            try buf_stdout.flush();
        } else if (done.*) break else std.Thread.sleep(100_000);
        // If the queue is empty and the done flag is not set, wait for 100 microseconds.
    }
}

/// This function represents a worker thread that generates messages and adds them to a queue.
///
/// Parameters:
/// - `id`: The identifier of the thread.
/// - `q`: A pointer to the queue.
fn worker(id: u32, q: *Queue) void {
    var i: u32 = 0; // Initialize the counter.
    while (i < 100) : (i += 1) { // Loop until i reaches 100.
        var msg = Msg{ // Create a new message.
            .timestamp = std.time.timestamp(), // Set the timestamp to the current time.
            .thread_id = id, // Set the thread identifier.
            .text = undefined, // Initialize the text field.
        };
        _ = std.fmt.bufPrint(&msg.text, "Message {d}", .{i}) catch continue; // Format the text.
        while (!q.push(msg)) std.Thread.sleep(50_000); // Add the message to the queue.
    }
}
