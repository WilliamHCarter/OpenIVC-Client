const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const AudioHandler = @import("../audio_handler.zig").AudioHandler;

pub const AudioLevelState = struct {
    // Smoothed display values
    capture_display: f32 = 0.0,
    playback_display: f32 = 0.0,

    // Peak hold values
    capture_peak: f32 = 0.0,
    playback_peak: f32 = 0.0,
    peak_hold_frames: u32 = 0,

    // Visual settings
    show_db_scale: bool = true,
    vertical_layout: bool = false,
};

pub const DrawConfig = struct {
    base_x: f32,
    start_y: f32,
    width: f32,
    height: f32,
    margin: f32,
    scale: f32,
};

pub fn drawAudioLevels(state: *AudioLevelState, audio_handler: ?*AudioHandler, config: DrawConfig) void {
    const group_height = if (state.vertical_layout) 200.0 * config.scale else 100.0 * config.scale;

    // Draw the group box
    _ = rg.guiGroupBox(.{
        .x = config.base_x,
        .y = config.start_y,
        .width = config.width,
        .height = group_height,
    }, "Audio Levels");

    // Get current levels if audio handler exists
    var capture_level: f32 = 0.0;
    var playback_level: f32 = 0.0;

    if (audio_handler) |handler| {
        const levels = handler.getLevels();
        capture_level = levels.capture;
        playback_level = levels.playback;

        // Smooth the display values
        state.capture_display = state.capture_display * 0.7 + capture_level * 0.3;
        state.playback_display = state.playback_display * 0.7 + playback_level * 0.3;

        // Update peaks
        if (capture_level > state.capture_peak) {
            state.capture_peak = capture_level;
            state.peak_hold_frames = 120; // Hold for 2 seconds at 60fps
        }
        if (playback_level > state.playback_peak) {
            state.playback_peak = playback_level;
            state.peak_hold_frames = 120;
        }

        // Decay peaks
        if (state.peak_hold_frames > 0) {
            state.peak_hold_frames -= 1;
        } else {
            state.capture_peak *= 0.95;
            state.playback_peak *= 0.95;
        }
    }

    const inner_margin = 10.0 * config.scale;
    const bar_height = 20.0 * config.scale;
    const label_width = 80.0 * config.scale;

    var y_offset = config.start_y + 25.0 * config.scale;

    // Draw capture meter
    drawLevelMeter(
        "Capture:",
        state.capture_display,
        state.capture_peak,
        config.base_x + inner_margin,
        y_offset,
        config.width - (2 * inner_margin),
        bar_height,
        label_width,
        state.show_db_scale,
    );

    y_offset += bar_height + inner_margin;

    drawLevelMeter(
        "Playback:",
        state.playback_display,
        state.playback_peak,
        config.base_x + inner_margin,
        y_offset,
        config.width - (2 * inner_margin),
        bar_height,
        label_width,
        state.show_db_scale,
    );

    // Options
    y_offset += bar_height + (15.0 * config.scale);
    _ = rg.guiCheckBox(.{
        .x = config.base_x + inner_margin,
        .y = y_offset,
        .width = 20.0 * config.scale,
        .height = 20.0 * config.scale,
    }, "Show dB scale", &state.show_db_scale);
}

pub fn drawLevelMeter(
    label: []const u8,
    level: f32,
    peak: f32,
    x: f32,
    y: f32,
    total_width: f32,
    height: f32,
    label_width: f32,
    show_db: bool,
) void {
    // Draw label
    _ = rg.guiLabel(.{
        .x = x,
        .y = y,
        .width = label_width,
        .height = height,
    }, @ptrCast(label.ptr));

    const meter_x = x + label_width;
    const meter_width = total_width - label_width - 60.0;

    // Background
    rl.drawRectangle(
        @intFromFloat(meter_x),
        @intFromFloat(y),
        @intFromFloat(meter_width),
        @intFromFloat(height),
        rl.Color.dark_gray,
    );

    // Level bar
    const bar_width = meter_width * level;
    if (bar_width > 0) {
        // Green to yellow to red gradient based on level
        const color = if (level < 0.5)
            rl.Color.green
        else if (level < 0.8)
            rl.Color.gold
        else
            rl.Color.red;

        rl.drawRectangle(
            @intFromFloat(meter_x),
            @intFromFloat(y),
            @intFromFloat(bar_width),
            @intFromFloat(height),
            color,
        );
    }

    // Peak indicator
    if (peak > 0.01) {
        const peak_x = meter_x + (meter_width * peak) - 2;
        rl.drawRectangle(
            @intFromFloat(peak_x),
            @intFromFloat(y),
            2,
            @intFromFloat(height),
            rl.Color.white,
        );
    }

    // Border
    rl.drawRectangleLinesEx(.{
        .x = meter_x,
        .y = y,
        .width = meter_width,
        .height = height,
    }, 1, rl.Color.light_gray);

    // dB value
    if (show_db) {
        const db = AudioHandler.levelToDb(level);
        const db_text = rl.textFormat("%+.1f dB", .{db});
        _ = rg.guiLabel(.{
            .x = meter_x + meter_width + 5,
            .y = y,
            .width = 55,
            .height = height,
        }, db_text);
    }

    // Reference lines at -12dB and -6dB
    const ref_positions = [_]f32{ 0.25, 0.5 }; // -12dB and -6dB approximately
    for (ref_positions) |pos| {
        const ref_x = meter_x + (meter_width * pos);
        rl.drawLine(
            @intFromFloat(ref_x),
            @intFromFloat(y),
            @intFromFloat(ref_x),
            @intFromFloat(y + height),
            rl.Color{ .r = 100, .g = 100, .b = 100, .a = 100 },
        );
    }
}
