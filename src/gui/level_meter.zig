const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const AudioHandler = @import("../audio_handler.zig").AudioHandler;

pub const LevelMeterState = struct {
    display_level: f32 = 0.0,
    peak_level: f32 = 0.0,
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

pub fn updateLevel(state: *LevelMeterState, level: f32) void {
    // Smooth the display level
    state.display_level = state.display_level * 0.7 + level * 0.3;

    // Update peaks
    if (state.display_level > state.peak_level) {
        state.peak_level = state.display_level;
        state.peak_hold_frames = 120; // Hold for 2 seconds at 60fps
    }

    // Decay peaks
    if (state.peak_hold_frames > 0) {
        state.peak_hold_frames -= 1;
    } else {
        state.peak_level *= 0.95;
    }
}

pub fn drawAudioLevel(state: *LevelMeterState, level: f32, config: DrawConfig) void {
    // Update the level state
    updateLevel(state, level);

    const inner_margin = 10.0 * config.scale;
    const bar_height = 20.0 * config.scale;
    const label_width = 80.0 * config.scale;

    const y_offset = config.start_y + 25.0 * config.scale;

    drawLevelMeter(
        "Test:",
        state.display_level,
        state.peak_level,
        @intFromFloat(config.base_x + inner_margin),
        @intFromFloat(y_offset),
        @intFromFloat(config.width - (2 * inner_margin)),
        @intFromFloat(bar_height),
        @intFromFloat(label_width),
        state.show_db_scale,
    );

    _ = rg.guiCheckBox(.{
        .x = config.base_x + inner_margin,
        .y = y_offset + bar_height + 5.0 * config.scale,
        .width = 20.0 * config.scale,
        .height = 20.0 * config.scale,
    }, "Show dB scale", &state.show_db_scale);
}

pub fn drawLevelMeter(
    label: []const u8,
    level: f32,
    peak: f32,
    x: i32,
    y: i32,
    total_width: i32,
    height: i32,
    label_width: i32,
) void {
    // Draw label
    _ = rg.guiLabel(.{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
        .width = @floatFromInt(label_width),
        .height = @floatFromInt(height),
    }, @ptrCast(label.ptr));

    const meter_x = x + label_width;
    const meter_width = total_width - label_width;

    // Background
    rl.drawRectangle(meter_x, y, meter_width, height, rl.Color.dark_gray);

    // Level bar with gradient
    const bar_width = @as(i32, @intFromFloat(@as(f32, @floatFromInt(meter_width)) * level));
    if (bar_width > 0) {
        // Green to yellow to red gradient based on level
        const color = if (level < 0.5)
            rl.Color.green
        else if (level < 0.8)
            rl.Color.gold
        else
            rl.Color.red;

        rl.drawRectangle(meter_x, y, bar_width, height, color);
    }

    // Peak indicator
    if (peak > 0.01) {
        const peak_x = meter_x + @as(i32, @intFromFloat(@as(f32, @floatFromInt(meter_width)) * peak)) - 2;
        rl.drawRectangle(peak_x, y, 2, height, rl.Color.white);
    }

    // Border
    const rect_lines: rl.Rectangle = .{ .x = @floatFromInt(meter_x), .y = @floatFromInt(y), .width = @floatFromInt(meter_width), .height = @floatFromInt(height) };
    rl.drawRectangleLinesEx(rect_lines, 1, rl.Color.light_gray);

    // Reference lines at -12dB and -6dB
    const ref_positions = [_]f32{ 0.25, 0.5 }; // -12dB and -6dB approximately
    for (ref_positions) |pos| {
        const ref_x = meter_x + @as(i32, @intFromFloat(@as(f32, @floatFromInt(meter_width)) * pos));
        const l_color = rl.Color{ .r = 100, .g = 100, .b = 100, .a = 100 };
        rl.drawLine(ref_x, y, ref_x, y + height, l_color);
    }
}
