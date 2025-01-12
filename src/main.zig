const rl = @import("raylib");
const std = @import("std");
const gui = @import("gui.zig");
const builtin = @import("builtin");

const is_windows = builtin.os.tag == .windows;
const client = if (builtin.os.tag == .windows) @import("windows_h.zig").client;

pub fn main() anyerror!void {
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
    rl.setTargetFPS(0);

    // Initialize GUI state
    var gui_state = gui.GuiState.init();

    // Main loop
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        gui.drawGui(&gui_state);
        rl.endDrawing();
    }
}
