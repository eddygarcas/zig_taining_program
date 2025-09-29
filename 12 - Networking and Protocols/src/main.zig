/// The entry point of the program.
///
const std = @import("std");
/// This function is the main entry point of the program. It calls the `server` function and then calls the `client` function. If an error occurs during the execution of the `client` function, it is caught and printed to the standard error.
pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    try server();
    client() catch |err| std.debug.print("{}\n", .{err});
}

/// The client function.
///
/// This function represents the client in a client-server relationship. It connects to the server at the specified address and port, sends a message to the server, and then reads a message from the server.
pub fn client() !void {
    // Parse the IP address and port number into an `Address` object.
    const addr = std.net.Address.parseIp4("127.0.0.1", 9000) catch unreachable;
    // Establish a TCP connection to the server.
    var s = try std.net.tcpConnectToAddress(addr);
    defer s.close();

    // Send a message to the server.
    try s.writeAll("Hello, World!\n");
    // Read a message from the server.
    var buff: [6]u8 = undefined;
    const n = try s.read(&buff);
    // Print the received message.
    std.debug.print("{s}\n", .{buff[0..n]});
}

/// The server function.
///
/// This function represents the server in a client-server relationship. It listens for incoming connections on the specified address and port, accepts a connection, reads a message from the client, and then writes the same message back to the client.
pub fn server() !void {
    // Parse the IP address and port number into an `Address` object.
    const addr = std.net.Address.parseIp4("127.0.0.1", 9000) catch unreachable;
    // Create a TCP listener on the specified address and port.
    var serv = try std.net.Address.listen(addr, .{});
    defer serv.deinit();

    // Accept a connection from a client.
    var conn = try serv.accept();
    defer conn.stream.close();

    // Read a message from the client.
    var buff: [128]u8 = undefined;
    const n = try conn.stream.read(&buff);
    // Write the received message back to the client.
    try conn.stream.writeAll(buff[0..n]);
}