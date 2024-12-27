const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const ServerConnection = @import("server_connection.zig");
const SoundDevices = @import("sound_devices.zig");
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

    // Server Connection states
    const space: u8 = 32;
    var server_state = ServerConnection.ServerState{
        .nickname_buf = [_]u8{space} ** 128,
        .server_ip_buf = [_]u8{space} ** 128,
        .connection_status_buf = [_]u8{space} ** 128,
        .connected = false,
    };

    // Initialize default values
    @memcpy(server_state.nickname_buf[0..5], "Micro");
    @memcpy(server_state.server_ip_buf[0..9], "5.9.54.24");
    @memcpy(server_state.connection_status_buf[0..9], "Connected");

    // Radio Frequencies states
    var uhf_freq: [32]u8 = [_]u8{space} ** 32;
    var vhf_freq: [32]u8 = [_]u8{space} ** 32;
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
    var sound_state = SoundDevices.SoundState{
        .capture_device_index = 0,
        .playback_device_index = 0,
        .input_dropdown_open = false,
        .output_dropdown_open = false,
    };
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

        const base_x = @divFloor(currentWidth - group_width, 2) + group_padding;
        var current_y = margin * 4 + group_padding;
        // Server Connection Group
        const server_config = ServerConnection.DrawConfig{
            .base_x = base_x,
            .start_y = current_y,
            .group_width = group_width,
            .element_height = element_height,
            .label_width = label_width,
            .input_width = input_width,
            .button_width = button_width,
            .margin = margin,
            .scale = scale,
        };

        _ = ServerConnection.drawServerGroup(&server_state, server_config);

        // Radio Frequencies Group
        const radioGroupY = current_y + 8 + element_height + margin * 2;
        _ = rg.guiGroupBox(.{
            .x = @floatFromInt(@divTrunc((currentWidth - group_width), 2)),
            .y = @floatFromInt(radioGroupY),
            .width = @floatFromInt(group_width),
            .height = 160.0 * scale,
        }, "Radio Frequencies");

        current_y = radioGroupY + group_padding;

        // UHF Row
        _ = rg.guiLabel(.{ .x = @floatFromInt(base_x), .y = @floatFromInt(current_y), .width = @floatFromInt(freq_width), .height = @floatFromInt(element_height) }, "UHF Freq:");
        _ = rg.guiTextBox(.{ .x = @floatFromInt(base_x + freq_width), .y = @floatFromInt(current_y), .width = @floatFromInt(2 * freq_width), .height = @floatFromInt(element_height) }, @ptrCast(&uhf_freq), 14, true);
        _ = rg.guiButton(.{ .x = @floatFromInt(base_x + freq_width + 2 * freq_width + margin), .y = @floatFromInt(current_y), .width = @floatFromInt(button_width), .height = @floatFromInt(element_height) }, "Change FRQ");
        _ = rg.guiSlider(.{ .x = @floatFromInt(base_x + freq_width + 2 * freq_width + button_width + 20 + margin * 2), .y = @floatFromInt(current_y), .width = @floatFromInt(100), .height = @floatFromInt(element_height) }, "Vol:", "", &uhf_vol, 0, 10);
        _ = rg.guiCheckBox(.{ .x = @floatFromInt(base_x + group_width - 200), .y = @floatFromInt(current_y), .width = @floatFromInt(20), .height = @floatFromInt(element_height) }, "UHF Active (F1)", &uhf_active);
        current_y += element_height + margin;

        // VHF Row
        _ = rg.guiLabel(.{ .x = @floatFromInt(base_x), .y = @floatFromInt(current_y), .width = @floatFromInt(freq_width), .height = @floatFromInt(element_height) }, "VHF Freq:");
        _ = rg.guiTextBox(.{ .x = @floatFromInt(base_x + freq_width), .y = @floatFromInt(current_y), .width = @floatFromInt(2 * freq_width), .height = @floatFromInt(element_height) }, @ptrCast(&vhf_freq), 14, true);
        _ = rg.guiButton(.{ .x = @floatFromInt(base_x + freq_width + 2 * freq_width + margin), .y = @floatFromInt(current_y), .width = @floatFromInt(button_width), .height = @floatFromInt(element_height) }, "Change FRQ");
        _ = rg.guiSlider(.{ .x = @floatFromInt(base_x + freq_width + 2 * freq_width + button_width + 20 + margin * 2), .y = @floatFromInt(current_y), .width = @floatFromInt(100), .height = @floatFromInt(element_height) }, "Vol:", "", &vhf_vol, 0, 10);
        _ = rg.guiCheckBox(.{ .x = @floatFromInt(base_x + group_width - 200), .y = @floatFromInt(current_y), .width = @floatFromInt(20), .height = @floatFromInt(element_height) }, "VHF Active (F2)", &vhf_active);
        current_y += element_height + margin;

        // Control Row
        _ = rg.guiCheckBox(.{ .x = @floatFromInt(base_x), .y = @floatFromInt(current_y), .width = @floatFromInt(20), .height = @floatFromInt(element_height) }, "Force Local Control", &force_local);
        _ = rg.guiCheckBox(.{ .x = @floatFromInt(base_x + 150), .y = @floatFromInt(current_y), .width = @floatFromInt(20), .height = @floatFromInt(element_height) }, "AGC", &agc_enabled);
        _ = rg.guiSlider(.{ .x = @floatFromInt(base_x + 280), .y = @floatFromInt(current_y), .width = @floatFromInt(100), .height = @floatFromInt(element_height) }, "Intercom Vol:", "", &intercom_vol, 0, 10);
        _ = rg.guiCheckBox(.{ .x = @floatFromInt(base_x + group_width - 200), .y = @floatFromInt(current_y), .width = @floatFromInt(20), .height = @floatFromInt(element_height) }, "GUARD Active (F3)", &guard_active);

        // Sound Devices Group
        const sound_config = SoundDevices.DrawConfig{
            .base_x = base_x,
            .start_y = current_y,
            .group_width = group_width,
            .element_height = element_height,
            .label_width = label_width,
            .margin = margin,
            .scale = scale,
        };

        current_y = SoundDevices.drawSoundGroup(&sound_state, sound_config);
    }
}
