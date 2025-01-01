const std = @import("std");
const windows = std.os.windows;

// Constants
const IDENTITY_BUFSIZE = 1024;

// Error sets
const Ts3Error = error{
    DllLoadFailed,
    ProcAddressFailed,
    ConnectionHandlerFailed,
    IdentityCreationFailed,
    BufferTooSmall,
    ConnectionFailed,
    EmptyFile,
    IdentityReadFailed,
    IdentityWriteFailed,
    InvalidFunction,
};

// Function type definitions
const Ts3Functions = struct {
    init: *const fn ([*c]const ClientUIFunctions, u32, u32, u32, [*c]const u8) callconv(.C) u32,
    spawnHandler: *const fn (i32, [*c]u64) callconv(.C) i32,
    startConnection: *const fn (u64, [*c]const u8, [*c]const u8, u32, [*c]const u8, [*c]const [*c]const u8, [*c]const u8, [*c]const u8) callconv(.C) i32,
    createIdentity: *const fn ([*c][*c]u8) callconv(.C) i32,
    freeMemory: *const fn (?*anyopaque) callconv(.C) i32,

    const Self = @This();

    fn load(dll: windows.HMODULE) !Self {
        return Self{
            .init = try loadFunction(dll, "ts3client_initClientLib"),
            .spawnHandler = try loadFunction(dll, "ts3client_spawnNewServerConnectionHandler"),
            .startConnection = try loadFunction(dll, "ts3client_startConnection"),
            .createIdentity = try loadFunction(dll, "ts3client_createIdentity"),
            .freeMemory = try loadFunction(dll, "ts3client_freeMemory"),
        };
    }

    fn loadFunction(dll: windows.HMODULE, name: [:0]const u8) !anyopaque {
        return windows.GetProcAddress(dll, name) orelse return Ts3Error.ProcAddressFailed;
    }
};

const ConnectInfo = struct {
    ip: [*:0]const u8,
    port: u16,
};

const ClientUIFunctions = extern struct {
    dummy: u8,
};

// File operations
fn readIdentity(allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile("identity.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    if (content.len == 0) return Ts3Error.EmptyFile;
    return content;
}

fn writeIdentity(identity: []const u8) !void {
    const file = try std.fs.cwd().createFile("identity.txt", .{});
    defer file.close();

    try file.writeAll(identity);
}

// TeamSpeak client functions
fn initializeTeamspeak(funcs: *ClientUIFunctions, ts3: Ts3Functions) !void {
    @memset(@as([*]u8, @ptrCast(funcs))[0..@sizeOf(ClientUIFunctions)], 1);

    const backend = "SoundBackends";
    const result = ts3.init(funcs, 0, 0, 0, backend);
    if (result != 0) return Ts3Error.InvalidFunction;
}

fn createServerConnection(ts3: Ts3Functions) !u64 {
    var scHandlerID: u64 = undefined;
    if (ts3.spawnHandler(0, &scHandlerID) != 0) {
        return Ts3Error.ConnectionHandlerFailed;
    }
    return scHandlerID;
}

fn handleIdentity(allocator: std.mem.Allocator, ts3: Ts3Functions) ![]u8 {
    // Try reading existing identity
    return readIdentity(allocator) catch {
        // If reading fails, create new identity
        var id: [*c]u8 = undefined;
        if (ts3.createIdentity(&id) != 0) {
            return Ts3Error.IdentityCreationFailed;
        }
        defer ts3.freeMemory(id);

        const id_len = std.mem.len(id);
        if (id_len >= IDENTITY_BUFSIZE) {
            return Ts3Error.BufferTooSmall;
        }

        var new_identity = try allocator.alloc(u8, id_len + 1);
        @memcpy(new_identity[0..id_len], id[0..id_len]);
        new_identity[id_len] = 0;

        try writeIdentity(new_identity[0..id_len]);
        return new_identity;
    };
}

fn connectToServer(ts3: Ts3Functions, scHandlerID: u64, identity: []const u8, connect_info: ConnectInfo) !void {
    if (ts3.startConnection(scHandlerID, identity.ptr, connect_info.ip, connect_info.port, "client", null, "", "") != 0) {
        return Ts3Error.ConnectionFailed;
    }
}

pub fn main() !void {
    // Initialize
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try stdout.writeAll("Loading DLL.\n");

    // Load the DLL
    const dll = windows.LoadLibraryW(L("ts3client.dll")) orelse {
        const err = windows.kernel32.GetLastError();
        try stdout.print("Error code: {}\n", .{err});
        try stdout.writeAll("Failed to load ts3client.dll\n");
        return Ts3Error.DllLoadFailed;
    };
    defer windows.FreeLibrary(dll);

    try stdout.writeAll("DLL loaded successfully.\n");

    // Load all TeamSpeak functions
    const ts3 = try Ts3Functions.load(dll);

    // Initialize TeamSpeak
    var funcs: ClientUIFunctions = undefined;
    try initializeTeamspeak(&funcs, ts3);

    // Create server connection
    const scHandlerID = try createServerConnection(ts3);

    // Setup connection info
    const connect_info = ConnectInfo{
        .ip = "localhost",
        .port = 9989,
    };

    // Handle identity creation/loading
    const identity = try handleIdentity(allocator, ts3);
    defer allocator.free(identity);

    try stdout.print("Using identity: {s}\n", .{identity});
    try stdout.print("Connecting to {s}:{d}\n", .{ connect_info.ip, connect_info.port });

    // Connect to server
    try connectToServer(ts3, scHandlerID, identity, connect_info);
}

// Utility to create wide string literal
fn L(comptime str: []const u8) [*:0]const u16 {
    comptime {
        var buffer: [(str.len + 1) * 2]u16 = undefined;
        for (str, 0..) |c, i| {
            buffer[i] = c;
        }
        buffer[str.len] = 0;
        return &buffer;
    }
}
