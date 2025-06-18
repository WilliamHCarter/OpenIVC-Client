const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const ServerConnection = @import("gui/server_connection.zig");
const SoundDevices = @import("gui/sound_devices.zig");
const SoundState = @import("./sound_state.zig").SoundState;
const RadioFreq = @import("gui/radio_freq.zig");
const LevelMeter = @import("gui/level_meter.zig").LevelMeterState;
const AudioHandler = @import("audio_handler.zig").AudioHandler;

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
    screen_width: i32,
    screen_height: i32,
    server_state: ServerConnection.ServerState,
    radio_state: RadioFreq.RadioState,
    sound_state: *SoundState,
    capture_level_state: *LevelMeter.LevelMeterState,
    audio_handler: ?*AudioHandler,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !GuiState {
        const sound_state = try SoundState.init(allocator);

        const audio_handler = try AudioHandler.init(allocator, .{});
        try audio_handler.start();

        return GuiState{
            .theme_index = 5,
            .previous_theme_index = -1,
            .theme_dropdown_open = false,
            .screen_width = 800,
            .screen_height = 500,
            .server_state = ServerConnection.ServerState{},
            .radio_state = RadioFreq.RadioState{},
            .sound_state = sound_state,
            .audio_levels_state = AudioLevels.AudioLevelState{},
            .audio_handler = audio_handler,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *GuiState) void {
        self.sound_state.deinit();
        if (self.audio_handler) |handler| {
            handler.deinit();
        }
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

pub fn drawGui(state: *GuiState) !void {
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
    rg.guiSetStyle(rg.GuiControl.default, rg.GuiDefaultProperty.text_size, @intFromFloat(@max(14 * scale, 8)));
    rg.guiSetStyle(rg.GuiControl.default, rg.GuiDefaultProperty.text_spacing, @intFromFloat(@max(1 * scale, 1)));

    // Theme handling
    if (state.theme_index != state.previous_theme_index) {
        loadTheme(@as(Theme, @enumFromInt(state.theme_index)));
        state.previous_theme_index = state.theme_index;
    }

    const background_bounds = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = current_width,
        .height = @as(f32, @floatFromInt(currentHeight)),
    };
    _ = rg.guiPanel(background_bounds, null);

    // Draw FPS counter
    const fps_text = rl.textFormat("FPS: %d", .{rl.getFPS()});
    _ = rg.guiLabel(.{ .x = margin, .y = scale * 20.0, .width = scale * 150.0, .height = scale * 30.0 }, fps_text);

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
    try SoundDevices.drawSoundGroup(state.sound_state, sound_config);
    current_y += 100.0 * scale;

    // Draw audio levels
    const audio_levels_config = AudioLevels.DrawConfig{
        .base_x = @divFloor(current_width - group_width, 2),
        .start_y = current_y,
        .width = group_width,
        .height = 100.0 * scale,
        .margin = margin,
        .scale = scale,
    };
    AudioLevels.drawAudioLevels(&state.audio_levels_state, state.audio_handler, audio_levels_config);
}
