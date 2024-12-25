const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const RadioFreq = @import("./radio_freq.zig");

// Define available themes
const Theme = enum(i32) {
    Default = 0,
    Dark,
    Jungle,
    Candy,
    Cherry,
    Cyber,
};

pub fn loadTheme(theme: Theme) void {
    if (theme == .Default) {
        rg.guiLoadStyleDefault();
    } else {
        const path = switch (theme) {
            .Default => unreachable,
            .Dark => "src/styles/style_dark.rgs",
            .Jungle => "src/styles/style_jungle.rgs",
            .Candy => "src/styles/style_candy.rgs",
            .Cherry => "src/styles/style_cherry.rgs",
            .Cyber => "src/styles/style_cyber.rgs",
        };

        // Try to open the file to verify it exists
        const file = std.fs.cwd().openFile(path, .{}) catch |err| {
            std.debug.print("Error opening style file {s}: {any}\n", .{ path, err });
            return;
        };
        defer file.close();

        std.debug.print("Successfully opened style file: {s}\n", .{path});
        rg.guiLoadStyle(path);
    }
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screen_width = 800;
    const screen_height = 500;

    // Enable window resizing before initialization
    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screen_width, screen_height, "OpenIVC Client");
    defer rl.closeWindow();

    // Remove FPS cap by setting it to 0
    rl.setTargetFPS(0);

    // GUI state variables
    var theme_index: i32 = 0;
    var previous_theme_index: i32 = -1;
    var theme_dropdown_open = false;
    var input_dropdown_open = false;
    var output_dropdown_open = false;

    // Server Connection states
    const space: u8 = 32; // ASCII code for space character
    var nickname_buf: [128]u8 = [_]u8{space} ** 128;
    var server_ip_buf: [128]u8 = [_]u8{space} ** 128;
    var connection_status_buf: [128]u8 = [_]u8{space} ** 128;
    @memcpy(nickname_buf[0..5], "Micro");
    @memcpy(server_ip_buf[0..9], "5.9.54.24");
    @memcpy(connection_status_buf[0..9], "Connected");

    var radio_state = RadioFreq.RadioState{
        .uhf_freq = [_]u8{32} ** 32,
        .vhf_freq = [_]u8{32} ** 32,
        .uhf_vol = 6.0,
        .vhf_vol = 6.0,
        .intercom_vol = 0.0,
        .uhf_active = false,
        .vhf_active = false,
        .force_local = false,
        .agc_enabled = false,
        .guard_active = false,
    };

    // Sound device dropdowns
    var capture_device_index: i32 = 0;
    var playback_device_index: i32 = 0;

    // Load initial theme
    loadTheme(.Default);

    //--------------------------------------------------------------------------------------
    // Main game loop
    while (!rl.windowShouldClose()) {
        const currentWidth = rl.getScreenWidth();
        const currentHeight = rl.getScreenHeight();
        const scale: f32 = @min(@as(f32, @floatFromInt(currentWidth)) / @as(f32, @floatFromInt(screen_width)), @as(f32, @floatFromInt(currentHeight)) / @as(f32, @floatFromInt(screen_height)));

        // Base dimensions
        const margin = @as(i32, @intFromFloat(10.0 * scale));
        const group_width = @as(i32, @intFromFloat(600.0 * scale));
        const element_height = @as(i32, @intFromFloat(25.0 * scale));
        const label_width = @as(i32, @intFromFloat(100.0 * scale));
        const input_width = @as(i32, @intFromFloat(200.0 * scale));
        const button_width = @as(i32, @intFromFloat(100.0 * scale));
        const group_padding = @as(i32, @intFromFloat(20.0 * scale));
        const freq_width = @as(i32, @intFromFloat(60.0 * scale));

        // Theme handling
        if (theme_index != previous_theme_index) {
            loadTheme(@as(Theme, @enumFromInt(theme_index)));
            previous_theme_index = theme_index;
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.ray_white);

        // Top bar: FPS and Theme selector
        const fps_text = rl.textFormat("FPS: %d", .{rl.getFPS()});
        rl.drawText(fps_text, margin, margin, @as(i32, @intFromFloat(20.0 * scale)), rl.Color.dark_gray);

        const dropdownBounds = rl.Rectangle{
            .x = @floatFromInt(currentWidth - @as(i32, @intFromFloat(150.0 * scale)) - margin),
            .y = @floatFromInt(margin),
            .width = 150.0 * scale,
            .height = 20.0 * scale,
        };

        // Draw the dropdown box and get the result
        const result = rg.guiDropdownBox(dropdownBounds, "Default;Dark;Jungle;Candy;Cherry;Cyber", &theme_index, theme_dropdown_open);

        // Toggle the dropdown edit mode on click
        if (result == 1) {
            theme_dropdown_open = !theme_dropdown_open;
        }

        // Server Connection Group
        const serverGroupY = margin * 4;
        _ = rg.guiGroupBox(.{
            .x = @floatFromInt(@divTrunc((currentWidth - group_width), 2)),
            .y = @floatFromInt(serverGroupY),
            .width = @floatFromInt(group_width),
            .height = 130.0 * scale,
        }, "Server Connection");

        const baseX = @divFloor(currentWidth - group_width, 2) + group_padding;
        var currentY = serverGroupY + group_padding;

        // Server connection controls
        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(label_width), .height = @floatFromInt(element_height) }, "Nickname:");
        _ = rg.guiTextBox(.{ .x = @floatFromInt(baseX + label_width), .y = @floatFromInt(currentY), .width = @floatFromInt(input_width), .height = @floatFromInt(element_height) }, @ptrCast(&nickname_buf), 14, true);
        currentY += element_height + margin;

        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(label_width), .height = @floatFromInt(element_height) }, "Server IP/DNS:");
        _ = rg.guiTextBox(.{ .x = @floatFromInt(baseX + label_width), .y = @floatFromInt(currentY), .width = @floatFromInt(input_width), .height = @floatFromInt(element_height) }, @ptrCast(&server_ip_buf), 14, true);
        currentY += element_height + margin;

        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(label_width), .height = @floatFromInt(element_height) }, "Connection Status:");
        _ = rg.guiTextBox(.{ .x = @floatFromInt(baseX + label_width), .y = @floatFromInt(currentY), .width = @floatFromInt(input_width), .height = @floatFromInt(element_height) }, @ptrCast(&connection_status_buf), 14, false);
        _ = rg.guiButton(.{ .x = @floatFromInt(baseX + label_width + input_width + margin), .y = @floatFromInt(currentY), .width = @floatFromInt(button_width), .height = @floatFromInt(element_height) }, "Disconnect");

        const radio_config = RadioFreq.DrawConfig{
            .base_x = baseX,
            .start_y = currentY,
            .group_width = group_width,
            .element_height = element_height,
            .freq_width = freq_width,
            .button_width = button_width,
            .margin = margin,
            .scale = scale,
        };

        currentY = RadioFreq.drawRadioGroup(&radio_state, radio_config);

        // Sound Devices Group
        const soundGroupY = currentY + element_height + margin * 2;
        _ = rg.guiGroupBox(.{
            .x = @floatFromInt(@divTrunc((currentWidth - group_width), 2)),
            .y = @floatFromInt(soundGroupY),
            .width = @floatFromInt(group_width),
            .height = 100.0 * scale,
        }, "Sound Devices");

        currentY = soundGroupY + group_padding;

        // Sound device dropdowns
        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(label_width), .height = @floatFromInt(element_height) }, "Capture:");
        const inputDropdownBounds = rl.Rectangle{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY + element_height), .width = @floatFromInt(@divTrunc(group_width, 2) - margin * 2), .height = @floatFromInt(element_height) };
        // Draw the dropdown box and get the result
        const in_res = rg.guiDropdownBox(inputDropdownBounds, "Analogue 1+2;USB Device 1;Default Input", &capture_device_index, input_dropdown_open);

        // Toggle the dropdown edit mode on click
        if (in_res == 1) {
            input_dropdown_open = !input_dropdown_open;
        }

        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX + @divTrunc(group_width, 2)), .y = @floatFromInt(currentY), .width = @floatFromInt(label_width), .height = @floatFromInt(element_height) }, "Playback:");
        const outputDropdownBounds = rl.Rectangle{ .x = @floatFromInt(baseX + @divTrunc(group_width, 2)), .y = @floatFromInt(currentY + element_height), .width = @floatFromInt(@divTrunc(group_width, 2) - margin * 2), .height = @floatFromInt(element_height) };
        // Draw the dropdown box and get the result
        const out_res = rg.guiDropdownBox(outputDropdownBounds, "Default Output;Speakers;Headphones", &playback_device_index, output_dropdown_open);

        // Toggle the dropdown edit mode on click
        if (out_res == 1) {
            output_dropdown_open = !output_dropdown_open;
        }
    }
}
