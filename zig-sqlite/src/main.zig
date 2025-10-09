/// Imports the standard library.
const std = @import("std");

/// Imports the C standard library, which is used for interacting with SQLite.
const c = @cImport({
    // Includes the SQLite header file.
    @cInclude("sqlite3.h");
});

/// The allocator used by the program.
const Allocator = std.mem.Allocator;

/// The main function of the program.
pub fn main() !void {
    // Allocates memory using the page allocator.
    // Opens the database file at "./test.db".
    const db = try openDb();
    defer _ = c.sqlite3_close(db);

    // Executes the query "create table if not exists test (id integer primary key, name text)".
    try execQuery(db, "create table if not exists test (id integer primary key, name text)");
    // Executes the query "insert into test (name) values ('test')".
    try execQuery(db, "insert into test (name) values ('test')");

    try execQuery(db, "select * from test");
    // Prints a message to the standard error stream indicating that the query was executed successfully.
    std.debug.print("Query executed successfully\n", .{});
}

/// Opens the database file at the given path.
fn openDb() !*c.sqlite3 {
    // Duplicates the given string into a null-terminated array of characters.
    const c_path: [*:0]const u8 = "./test.db"; // ✅ string literal → zero-terminated

    // Opens the database file at the given path, returning an optional pointer to the database object.
    var db: ?*c.sqlite3 = null;
    // The return code of the sqlite3_open function, which is SQLITE_OK if the operation was successful.
    const rc = c.sqlite3_open(c_path, &db);
    if (rc != c.SQLITE_OK) return error.DbOpenFailed;
    // Returns the pointer to the database object.
    // Unwrap the optional pointer (?*T → *T), crash if null
    return db.?;
}

/// Executes the given query on the database at the given path.
fn execQuery(db: *c.sqlite3, c_sql: [*:0]const u8) !void {
    // Duplicates the given string into a null-terminated array of characters.
    //defer db.allocator.free(c_sql);

    // A pointer to a null-terminated array of characters containing an error message.
    const errmsg: [*c][*c]u8 = null;
    // The return code of the sqlite3_exec function, which is SQLITE_OK if the operation was successful.
    const rc = c.sqlite3_exec(db, c_sql, null, null, errmsg);
    if (rc != c.SQLITE_OK) {
        // If there was an error, prints the error message to the standard error stream.
        if (errmsg) |err| {
            std.debug.print("SQL error: {}\n", .{err});
            c.sqlite3_free(err); // ✅ SQLite allocates it, so use sqlite3_free
        }
        // Returns the error QueryFailed.
        return error.QueryFailed;
    }
}
