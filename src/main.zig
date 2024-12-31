const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const ServerConnection = @import("server_connection.zig");
const SoundDevices = @import("sound_devices.zig");
const RadioFreq = @import("radio_freq.zig");
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
        .nickname_len = 0,
        .server_ip_len = 0,
        .connected = false,
        .nickname_edit = false,
        .server_ip_edit = false,
    };

    // Initialize default values
    @memcpy(server_state.nickname_buf[0..5], "Micro");
    @memcpy(server_state.server_ip_buf[0..9], "5.9.54.24");
    @memcpy(server_state.connection_status_buf[0..9], "Connected");

    // Radio Frequencies states
    var radio_state = RadioFreq.RadioState{
        .uhf_freq = [_]u8{32} ** 32,
        .vhf_freq = [_]u8{32} ** 32,
        .uhf_freq_len = 0,
        .vhf_freq_len = 0,
        .uhf_edit = false,
        .vhf_edit = false,
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
        const current_width = @as(f32, @floatFromInt(rl.getScreenWidth()));
        const currentHeight = rl.getScreenHeight();
        const scale: f32 = @min((current_width / @as(f32, @floatFromInt(screen_width))), @as(f32, @floatFromInt(currentHeight)) / @as(f32, @floatFromInt(screen_height)));

        // Base dimensions
        const margin: f32 = 10.0 * scale;
        const group_width: f32 = 600.0 * scale;
        const element_height: f32 = 25.0 * scale;
        const label_width: f32 = 100.0 * scale;
        const input_width: f32 = 200.0 * scale;
        const button_width: f32 = 100.0 * scale;
        const group_padding: f32 = 20.0 * scale;
        const freq_width: f32 = 80.0 * scale;
        rg.guiSetStyle(rg.GuiControl.default, @intFromEnum(rg.GuiDefaultProperty.text_size), @intFromFloat(@max(14 * scale, 8)));
        rg.guiSetStyle(rg.GuiControl.default, @intFromEnum(rg.GuiDefaultProperty.text_spacing), @intFromFloat(@max(1 * scale, 1)));

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
        rl.drawText(fps_text, @intFromFloat(margin), @intFromFloat(margin), @as(i32, @intFromFloat(20.0 * scale)), rl.Color.dark_gray);

        const dropdownBounds = rl.Rectangle{
            .x = current_width - (150.0 * scale) - margin,
            .y = margin,
            .width = 150.0 * scale,
            .height = 20.0 * scale,
        };

        // Draw the dropdown box and get the result
        const result = rg.guiDropdownBox(dropdownBounds, "Default;Dark;Jungle;Candy;Cherry;Cyber", &theme_index, theme_dropdown_open);

        // Toggle the dropdown edit mode on click
        if (result == 1) {
            theme_dropdown_open = !theme_dropdown_open;
        }

        const base_x = @divFloor(current_width - group_width, 2) + group_padding;
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

        ServerConnection.drawServerGroup(&server_state, server_config);
        current_y += 120.0 * scale; // Spacing between panels

        // Radio Frequencies Group
        const radio_config = RadioFreq.DrawConfig{
            .base_x = base_x,
            .start_y = current_y,
            .group_width = group_width,
            .element_height = element_height,
            .freq_width = freq_width,
            .button_width = button_width,
            .margin = margin,
            .scale = scale,
        };

        RadioFreq.drawRadioGroup(&radio_state, radio_config);
        current_y += 170.0 * scale; // Spacing between panels

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

        SoundDevices.drawSoundGroup(&sound_state, sound_config);
    }
}
