const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");

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
    var nickname_buf: [128]u8 = undefined;
    var server_ip_buf: [128]u8 = undefined;
    var connection_status_buf: [128]u8 = undefined;
    @memcpy(nickname_buf[0..5], "Micro");
    @memcpy(server_ip_buf[0..9], "5.9.54.24");
    @memcpy(connection_status_buf[0..9], "Connected");

    // Radio Frequencies states
    var uhf_freq: [32]u8 = undefined;
    var vhf_freq: [32]u8 = undefined;
    @memcpy(uhf_freq[0..6], "339750");
    @memcpy(vhf_freq[0..4], "1234");

    var uhf_vol: f32 = 6.0;
    var vhf_vol: f32 = 6.0;
    var intercom_vol: f32 = 0.0;

    // Checkbox states
    var uhf_active = false;
    var vhf_active = false;
    var force_local = false;
    var agc_enabled = false;
    var guard_active = false;

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
        const groupWidth = @as(i32, @intFromFloat(600.0 * scale));
        const elementHeight = @as(i32, @intFromFloat(25.0 * scale));
        const labelWidth = @as(i32, @intFromFloat(100.0 * scale));
        const inputWidth = @as(i32, @intFromFloat(200.0 * scale));
        const buttonWidth = @as(i32, @intFromFloat(100.0 * scale));
        const groupPadding = @as(i32, @intFromFloat(20.0 * scale));

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
            .x = @floatFromInt(@divTrunc((currentWidth - groupWidth), 2)),
            .y = @floatFromInt(serverGroupY),
            .width = @floatFromInt(groupWidth),
            .height = 130.0 * scale,
        }, "Server Connection");

        const baseX = @divFloor(currentWidth - groupWidth, 2) + groupPadding;
        var currentY = serverGroupY + groupPadding;

        // Server connection controls
        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(labelWidth), .height = @floatFromInt(elementHeight) }, "Nickname:");
        _ = rg.guiTextBox(.{ .x = @floatFromInt(baseX + labelWidth), .y = @floatFromInt(currentY), .width = @floatFromInt(inputWidth), .height = @floatFromInt(elementHeight) }, @ptrCast(&nickname_buf), 14, true);
        currentY += elementHeight + margin;

        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(labelWidth), .height = @floatFromInt(elementHeight) }, "Server IP/DNS:");
        _ = rg.guiTextBox(.{ .x = @floatFromInt(baseX + labelWidth), .y = @floatFromInt(currentY), .width = @floatFromInt(inputWidth), .height = @floatFromInt(elementHeight) }, @ptrCast(&server_ip_buf), 14, true);
        currentY += elementHeight + margin;

        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(labelWidth), .height = @floatFromInt(elementHeight) }, "Connection Status:");
        _ = rg.guiTextBox(.{ .x = @floatFromInt(baseX + labelWidth), .y = @floatFromInt(currentY), .width = @floatFromInt(inputWidth), .height = @floatFromInt(elementHeight) }, @ptrCast(&connection_status_buf), 14, false);
        _ = rg.guiButton(.{ .x = @floatFromInt(baseX + labelWidth + inputWidth + margin), .y = @floatFromInt(currentY), .width = @floatFromInt(buttonWidth), .height = @floatFromInt(elementHeight) }, "Disconnect");

        // Radio Frequencies Group
        const radioGroupY = currentY + 8 + elementHeight + margin * 2;
        _ = rg.guiGroupBox(.{
            .x = @floatFromInt(@divTrunc((currentWidth - groupWidth), 2)),
            .y = @floatFromInt(radioGroupY),
            .width = @floatFromInt(groupWidth),
            .height = 160.0 * scale,
        }, "Radio Frequencies");

        currentY = radioGroupY + groupPadding;

        // UHF Row
        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(labelWidth), .height = @floatFromInt(elementHeight) }, "UHF Freq:");
        _ = rg.guiTextBox(.{ .x = @floatFromInt(baseX + labelWidth), .y = @floatFromInt(currentY), .width = @floatFromInt(inputWidth), .height = @floatFromInt(elementHeight) }, @ptrCast(&uhf_freq), 14, true);
        _ = rg.guiButton(.{ .x = @floatFromInt(baseX + labelWidth + inputWidth + margin), .y = @floatFromInt(currentY), .width = @floatFromInt(buttonWidth), .height = @floatFromInt(elementHeight) }, "Change FRQ");
        _ = rg.guiSlider(.{ .x = @floatFromInt(baseX + labelWidth + inputWidth + buttonWidth + margin * 2), .y = @floatFromInt(currentY), .width = @floatFromInt(100), .height = @floatFromInt(elementHeight) }, "Vol:", "", &uhf_vol, 0, 10);
        _ = rg.guiCheckBox(.{ .x = @floatFromInt(baseX + groupWidth - 100), .y = @floatFromInt(currentY), .width = @floatFromInt(20), .height = @floatFromInt(elementHeight) }, "UHF Active (F1)", &uhf_active);
        currentY += elementHeight + margin;

        // VHF Row
        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(labelWidth), .height = @floatFromInt(elementHeight) }, "VHF Freq:");
        _ = rg.guiTextBox(.{ .x = @floatFromInt(baseX + labelWidth), .y = @floatFromInt(currentY), .width = @floatFromInt(inputWidth), .height = @floatFromInt(elementHeight) }, @ptrCast(&vhf_freq), 14, true);
        _ = rg.guiButton(.{ .x = @floatFromInt(baseX + labelWidth + inputWidth + margin), .y = @floatFromInt(currentY), .width = @floatFromInt(buttonWidth), .height = @floatFromInt(elementHeight) }, "Change FRQ");
        _ = rg.guiSlider(.{ .x = @floatFromInt(baseX + labelWidth + inputWidth + buttonWidth + margin * 2), .y = @floatFromInt(currentY), .width = @floatFromInt(100), .height = @floatFromInt(elementHeight) }, "Vol:", "", &vhf_vol, 0, 10);
        _ = rg.guiCheckBox(.{ .x = @floatFromInt(baseX + groupWidth - 100), .y = @floatFromInt(currentY), .width = @floatFromInt(20), .height = @floatFromInt(elementHeight) }, "VHF Active (F2)", &vhf_active);
        currentY += elementHeight + margin;

        // Control Row
        _ = rg.guiCheckBox(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(20), .height = @floatFromInt(elementHeight) }, "Force Local Control", &force_local);
        _ = rg.guiCheckBox(.{ .x = @floatFromInt(baseX + 150), .y = @floatFromInt(currentY), .width = @floatFromInt(20), .height = @floatFromInt(elementHeight) }, "AGC", &agc_enabled);
        _ = rg.guiSlider(.{ .x = @floatFromInt(baseX + 250), .y = @floatFromInt(currentY), .width = @floatFromInt(100), .height = @floatFromInt(elementHeight) }, "Intercom Vol:", "", &intercom_vol, 0, 10);
        _ = rg.guiCheckBox(.{ .x = @floatFromInt(baseX + groupWidth - 100), .y = @floatFromInt(currentY), .width = @floatFromInt(20), .height = @floatFromInt(elementHeight) }, "GUARD Active (F3)", &guard_active);

        // Sound Devices Group
        const soundGroupY = currentY + elementHeight + margin * 2;
        _ = rg.guiGroupBox(.{
            .x = @floatFromInt(@divTrunc((currentWidth - groupWidth), 2)),
            .y = @floatFromInt(soundGroupY),
            .width = @floatFromInt(groupWidth),
            .height = 100.0 * scale,
        }, "Sound Devices");

        currentY = soundGroupY + groupPadding;

        // Sound device dropdowns
        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY), .width = @floatFromInt(labelWidth), .height = @floatFromInt(elementHeight) }, "Capture:");
        const inputDropdownBounds = rl.Rectangle{ .x = @floatFromInt(baseX), .y = @floatFromInt(currentY + elementHeight), .width = @floatFromInt(@divTrunc(groupWidth, 2) - margin * 2), .height = @floatFromInt(elementHeight) };
        // Draw the dropdown box and get the result
        const in_res = rg.guiDropdownBox(inputDropdownBounds, "Analogue 1+2;USB Device 1;Default Input", &capture_device_index, input_dropdown_open);

        // Toggle the dropdown edit mode on click
        if (in_res == 1) {
            input_dropdown_open = !input_dropdown_open;
        }

        _ = rg.guiLabel(.{ .x = @floatFromInt(baseX + @divTrunc(groupWidth, 2)), .y = @floatFromInt(currentY), .width = @floatFromInt(labelWidth), .height = @floatFromInt(elementHeight) }, "Playback:");
        const outputDropdownBounds = rl.Rectangle{ .x = @floatFromInt(baseX + @divTrunc(groupWidth, 2)), .y = @floatFromInt(currentY + elementHeight), .width = @floatFromInt(@divTrunc(groupWidth, 2) - margin * 2), .height = @floatFromInt(elementHeight) };
        // Draw the dropdown box and get the result
        const out_res = rg.guiDropdownBox(outputDropdownBounds, "Default Output;Speakers;Headphones", &playback_device_index, output_dropdown_open);

        // Toggle the dropdown edit mode on click
        if (out_res == 1) {
            output_dropdown_open = !output_dropdown_open;
        }
    }
}
