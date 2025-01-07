const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const ServerConnection = @import("server_connection.zig");
const SoundDevices = @import("sound_devices.zig");
const RadioFreq = @import("radio_freq.zig");

// Define available themes
pub const Theme = enum(i32) {
    Default = 0,
    Dark,
    Jungle,
    Candy,
    Cherry,
    Cyber,
};

// GUI state structure
pub const GuiState = struct {
    theme_index: i32,
    previous_theme_index: i32,
    theme_dropdown_open: bool,
    server_state: ServerConnection.ServerState,
    radio_state: RadioFreq.RadioState,
    sound_state: SoundDevices.SoundState,
    screen_width: i32,
    screen_height: i32,

    pub fn init() GuiState {
        const space: u8 = 32;
        var state = GuiState{
            .theme_index = 0,
            .previous_theme_index = -1,
            .theme_dropdown_open = false,
            .screen_width = 800,
            .screen_height = 500,
            .server_state = ServerConnection.ServerState{
                .nickname_buf = [_]u8{space} ** 128,
                .server_ip_buf = [_]u8{space} ** 128,
                .connection_status_buf = [_]u8{space} ** 128,
                .nickname_len = 0,
                .server_ip_len = 0,
                .connected = false,
                .nickname_edit = false,
                .server_ip_edit = false,
            },
            .radio_state = RadioFreq.RadioState{
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
            },
            .sound_state = SoundDevices.SoundState{
                .capture_device_index = 0,
                .playback_device_index = 0,
                .input_dropdown_open = false,
                .output_dropdown_open = false,
            },
        };

        // Initialize default values
        @memcpy(state.server_state.nickname_buf[0..5], "Micro");
        @memcpy(state.server_state.server_ip_buf[0..9], "5.9.54.24");
        @memcpy(state.server_state.connection_status_buf[0..9], "Connected");

        return state;
    }
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

pub fn drawGui(state: *GuiState) void {
    const current_width = @as(f32, @floatFromInt(rl.getScreenWidth()));
    const currentHeight = rl.getScreenHeight();
    const scale: f32 = @min((current_width / @as(f32, @floatFromInt(state.screen_width))), @as(f32, @floatFromInt(currentHeight)) / @as(f32, @floatFromInt(state.screen_height)));

    // Base dimensions
    const margin: f32 = 10.0 * scale;
    const group_width: f32 = 600.0 * scale;
    const element_height: f32 = 25.0 * scale;
    const label_width: f32 = 100.0 * scale;
    const input_width: f32 = 200.0 * scale;
    const button_width: f32 = 100.0 * scale;
    const group_padding: f32 = 20.0 * scale;
    const freq_width: f32 = 80.0 * scale;

    // Set GUI style based on scale
    rg.guiSetStyle(rg.GuiControl.default, @intFromEnum(rg.GuiDefaultProperty.text_size), @intFromFloat(@max(14 * scale, 8)));
    rg.guiSetStyle(rg.GuiControl.default, @intFromEnum(rg.GuiDefaultProperty.text_spacing), @intFromFloat(@max(1 * scale, 1)));

    // Theme handling
    if (state.theme_index != state.previous_theme_index) {
        loadTheme(@as(Theme, @enumFromInt(state.theme_index)));
        state.previous_theme_index = state.theme_index;
    }

    rl.clearBackground(rl.Color.ray_white);

    // Draw FPS counter
    const fps_text = rl.textFormat("FPS: %d", .{rl.getFPS()});
    rl.drawText(fps_text, @intFromFloat(margin), @intFromFloat(margin), @as(i32, @intFromFloat(20.0 * scale)), rl.Color.dark_gray);

    // Theme dropdown
    const dropdownBounds = rl.Rectangle{
        .x = current_width - (150.0 * scale) - margin,
        .y = margin,
        .width = 150.0 * scale,
        .height = 20.0 * scale,
    };

    const result = rg.guiDropdownBox(dropdownBounds, "Default;Dark;Jungle;Candy;Cherry;Cyber", &state.theme_index, state.theme_dropdown_open);
    if (result == 1) {
        state.theme_dropdown_open = !state.theme_dropdown_open;
    }

    // Calculate positions for components
    const base_x = @divFloor(current_width - group_width, 2) + group_padding;
    var current_y = margin * 4 + group_padding;

    // Draw server connection group
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
    ServerConnection.drawServerGroup(&state.server_state, server_config);
    current_y += 120.0 * scale;

    // Draw radio frequencies group
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
    RadioFreq.drawRadioGroup(&state.radio_state, radio_config);
    current_y += 170.0 * scale;

    // Draw sound devices group
    const sound_config = SoundDevices.DrawConfig{
        .base_x = base_x,
        .start_y = current_y,
        .group_width = group_width,
        .element_height = element_height,
        .label_width = label_width,
        .margin = margin,
        .scale = scale,
    };
    SoundDevices.drawSoundGroup(&state.sound_state, sound_config);
}
