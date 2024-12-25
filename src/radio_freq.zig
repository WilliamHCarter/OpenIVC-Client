const rl = @import("raylib");
const rg = @import("raygui");

pub const RadioState = struct {
    uhf_freq: [32]u8,
    vhf_freq: [32]u8,
    uhf_vol: f32,
    vhf_vol: f32,
    intercom_vol: f32,
    uhf_active: bool,
    vhf_active: bool,
    force_local: bool,
    agc_enabled: bool,
    guard_active: bool,
};

pub const DrawConfig = struct {
    base_x: i32,
    start_y: i32,
    group_width: i32,
    element_height: i32,
    freq_width: i32,
    button_width: i32,
    margin: i32,
    scale: f32,
};

// Returns the final Y position after drawing
pub fn drawRadioGroup(state: *RadioState, config: DrawConfig) i32 {
    var current_y = config.start_y;

    // Draw the group box
    _ = rg.guiGroupBox(.{
        .x = @floatFromInt(config.base_x),
        .y = @floatFromInt(current_y),
        .width = @floatFromInt(config.group_width),
        .height = 160.0 * config.scale,
    }, "Radio Frequencies");

    current_y += @as(i32, @intFromFloat(20.0 * config.scale)); // Group padding

    // UHF Row
    _ = rg.guiLabel(.{ .x = @floatFromInt(config.base_x), .y = @floatFromInt(current_y), .width = @floatFromInt(config.freq_width), .height = @floatFromInt(config.element_height) }, "UHF Freq:");
    _ = rg.guiTextBox(.{
        .x = @floatFromInt(config.base_x + config.freq_width),
        .y = @floatFromInt(current_y),
        .width = @floatFromInt(2 * config.freq_width),
        .height = @floatFromInt(config.element_height),
    }, @ptrCast(&state.uhf_freq), 14, true);
    _ = rg.guiButton(.{
        .x = @floatFromInt(config.base_x + config.freq_width + 2 * config.freq_width + config.margin),
        .y = @floatFromInt(current_y),
        .width = @floatFromInt(config.button_width),
        .height = @floatFromInt(config.element_height),
    }, "Change FRQ");
    _ = rg.guiSlider(.{
        .x = @floatFromInt(config.base_x + config.freq_width + 2 * config.freq_width + config.button_width + 20 + config.margin * 2),
        .y = @floatFromInt(current_y),
        .width = @floatFromInt(100),
        .height = @floatFromInt(config.element_height),
    }, "Vol:", "", &state.uhf_vol, 0, 10);
    _ = rg.guiCheckBox(.{
        .x = @floatFromInt(config.base_x + config.group_width - 200),
        .y = @floatFromInt(current_y),
        .width = @floatFromInt(20),
        .height = @floatFromInt(config.element_height),
    }, "UHF Active (F1)", &state.uhf_active);

    current_y += config.element_height + config.margin;

    // VHF Row
    _ = rg.guiLabel(.{ .x = @floatFromInt(config.base_x), .y = @floatFromInt(current_y), .width = @floatFromInt(config.freq_width), .height = @floatFromInt(config.element_height) }, "VHF Freq:");
    _ = rg.guiTextBox(.{ .x = @floatFromInt(config.base_x + config.freq_width), .y = @floatFromInt(current_y), .width = @floatFromInt(2 * config.freq_width), .height = @floatFromInt(config.element_height) }, @ptrCast(&state.vhf_freq), 14, true);
    _ = rg.guiButton(.{ .x = @floatFromInt(config.base_x + config.freq_width + 2 * config.freq_width + config.margin), .y = @floatFromInt(current_y), .width = @floatFromInt(config.button_width), .height = @floatFromInt(config.element_height) }, "Change FRQ");
    _ = rg.guiSlider(.{ .x = @floatFromInt(config.base_x + config.freq_width + 2 * config.freq_width + config.button_width + 20 + config.margin * 2), .y = @floatFromInt(current_y), .width = @floatFromInt(100), .height = @floatFromInt(config.element_height) }, "Vol:", "", &state.vhf_vol, 0, 10);
    _ = rg.guiCheckBox(.{ .x = @floatFromInt(config.base_x + config.group_width - 200), .y = @floatFromInt(current_y), .width = @floatFromInt(20), .height = @floatFromInt(config.element_height) }, "VHF Active (F2)", &state.vhf_active);
    current_y += config.element_height + config.margin;

    // Control Row
    _ = rg.guiCheckBox(.{
        .x = @floatFromInt(config.base_x),
        .y = @floatFromInt(current_y),
        .width = @floatFromInt(20),
        .height = @floatFromInt(config.element_height),
    }, "Force Local Control", &state.force_local);

    _ = rg.guiCheckBox(.{
        .x = @floatFromInt(config.base_x + 150),
        .y = @floatFromInt(current_y),
        .width = @floatFromInt(20),
        .height = @floatFromInt(config.element_height),
    }, "AGC", &state.agc_enabled);

    _ = rg.guiSlider(.{
        .x = @floatFromInt(config.base_x + 280),
        .y = @floatFromInt(current_y),
        .width = @floatFromInt(100),
        .height = @floatFromInt(config.element_height),
    }, "Intercom Vol:", "", &state.intercom_vol, 0, 10);

    _ = rg.guiCheckBox(.{
        .x = @floatFromInt(config.base_x + config.group_width - 200),
        .y = @floatFromInt(current_y),
        .width = @floatFromInt(20),
        .height = @floatFromInt(config.element_height),
    }, "GUARD Active (F3)", &state.guard_active);

    return current_y + config.element_height + config.margin;
}
