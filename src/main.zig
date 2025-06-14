const rl = @import("raylib");
const std = @import("std");
const gui = @import("gui.zig");
const builtin = @import("builtin");

const is_windows = builtin.os.tag == .windows;
const client = if (builtin.os.tag == .windows) @import("windows_h.zig").client;

pub fn main() anyerror!void {
    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize Windows client if applicable
    if (is_windows) {
        const err = client.startClient();
        if (err != 0) {
            std.debug.print("Failed to initialize client: {}\n", .{err});
        } else {
            std.debug.print("Client initialized successfully.\n", .{});
        }
    }

    // Initialize window
    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(800, 500, "OpenIVC Client");
    defer rl.closeWindow();
    rl.setTargetFPS(rl.getMonitorRefreshRate(rl.getCurrentMonitor())); //set to 0 to uncap
    // Initialize GUI state
    var gui_state = try gui.GuiState.init(allocator);
    defer gui_state.deinit();

    // Main loop
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        try gui.drawGui(&gui_state);
        rl.endDrawing();
    }
}
