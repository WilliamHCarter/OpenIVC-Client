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
    base_x: f32,
    start_y: f32,
    group_width: f32,
    element_height: f32,
    freq_width: f32,
    button_width: f32,
    margin: f32,
    scale: f32,
};

// Returns the final Y position after drawing
pub fn drawRadioGroup(state: *RadioState, config: DrawConfig) void {
    var current_y = config.start_y;
    var textbox_bounds: rl.Rectangle = rl.Rectangle.init(config.base_x + config.freq_width, current_y, 1.6 * config.freq_width, config.element_height);
    var button_bounds: rl.Rectangle = rl.Rectangle.init(config.base_x + config.freq_width + (1.6 * config.freq_width) + config.margin, current_y, config.button_width, config.element_height);
    var slider_bounds: rl.Rectangle = rl.Rectangle.init(config.base_x + config.freq_width + (1.6 * config.freq_width) + config.button_width + (30.0 * config.scale) + (config.margin * 2.0), current_y, 60.0 * config.scale, config.element_height);
    var checkbox_bounds: rl.Rectangle = rl.Rectangle.init(config.base_x + config.group_width - (170.0 * config.scale), current_y, config.element_height, config.element_height);

    // Draw the group box
    _ = rg.guiGroupBox(.{
        .x = (@as(f32, @floatFromInt(rl.getScreenWidth())) - config.group_width) / 2,
        .y = current_y,
        .width = config.group_width,
        .height = 160.0 * config.scale,
    }, "Radio Frequencies");

    current_y += 20.0 * config.scale; // Group padding
    slider_bounds.y = current_y;
    checkbox_bounds.y = current_y;
    textbox_bounds.y = current_y;
    button_bounds.y = current_y;

    // UHF Row
    _ = rg.guiLabel(.{ .x = config.base_x, .y = current_y, .width = config.freq_width, .height = config.element_height }, "UHF Freq:");
    _ = rg.guiTextBox(textbox_bounds, @ptrCast(&state.uhf_freq), 14, true);
    _ = rg.guiButton(button_bounds, "Change FRQ");
    _ = rg.guiSlider(slider_bounds, "Vol:", "", &state.uhf_vol, 0, 10);
    _ = rg.guiCheckBox(checkbox_bounds, "UHF Active (F1)", &state.uhf_active);

    current_y += config.element_height + config.margin;
    slider_bounds.y = current_y;
    checkbox_bounds.y = current_y;
    textbox_bounds.y = current_y;
    button_bounds.y = current_y;

    // VHF Row
    _ = rg.guiLabel(.{ .x = config.base_x, .y = current_y, .width = config.freq_width, .height = config.element_height }, "VHF Freq:");
    _ = rg.guiTextBox(textbox_bounds, @ptrCast(&state.vhf_freq), 14, true);
    _ = rg.guiButton(button_bounds, "Change FRQ");
    _ = rg.guiSlider(slider_bounds, "Vol:", "", &state.vhf_vol, 0, 10);
    _ = rg.guiCheckBox(checkbox_bounds, "VHF Active (F2)", &state.vhf_active);

    current_y += config.element_height + config.margin;
    slider_bounds.y = current_y;
    checkbox_bounds.y = current_y;
    textbox_bounds.y = current_y;
    button_bounds.y = current_y;

    // Control Row
    _ = rg.guiCheckBox(.{
        .x = config.base_x,
        .y = current_y,
        .width = config.element_height,
        .height = config.element_height,
    }, "Force Local Control", &state.force_local);

    _ = rg.guiCheckBox(.{
        .x = config.base_x + (180.0 * config.scale),
        .y = current_y,
        .width = config.element_height,
        .height = config.element_height,
    }, "AGC", &state.agc_enabled);

    _ = rg.guiSlider(slider_bounds, "Intercom Vol:", "", &state.intercom_vol, 0, 10);

    _ = rg.guiCheckBox(.{
        .x = config.base_x + config.group_width - (170.0 * config.scale),
        .y = current_y,
        .width = config.element_height,
        .height = config.element_height,
    }, "GUARD Active (F3)", &state.guard_active);
}
