const rl = @import("raylib");
const rg = @import("raygui");
const InputBox = @import("ui_inputbox.zig");

pub const RadioState = struct {
    uhf_freq: [32]u8,
    vhf_freq: [32]u8,
    uhf_freq_len: usize,
    vhf_freq_len: usize,
    uhf_edit: bool,
    vhf_edit: bool,
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

pub fn drawRadioGroup(state: *RadioState, config: DrawConfig) void {
    var current_y = config.start_y;
    var textbox_bounds = rl.Rectangle.init(config.base_x + config.freq_width, current_y, 1.6 * config.freq_width, config.element_height);
    var button_bounds = rl.Rectangle.init(textbox_bounds.x + (1.6 * config.freq_width) + config.margin, current_y, config.button_width, config.element_height);
    var slider_bounds = rl.Rectangle.init(button_bounds.x + config.button_width + (25.0 * config.scale) + config.margin, current_y, 60.0 * config.scale, config.element_height);
    var checkbox_bounds = rl.Rectangle.init(config.base_x + config.group_width - (175.0 * config.scale), current_y, config.element_height, config.element_height);
    const bounds_ptrs = [_]*rl.Rectangle{ &slider_bounds, &checkbox_bounds, &textbox_bounds, &button_bounds };

    // Draw the group box
    _ = rg.guiGroupBox(.{
        .x = (@as(f32, @floatFromInt(rl.getScreenWidth())) - config.group_width) / 2,
        .y = current_y,
        .width = config.group_width,
        .height = 160.0 * config.scale,
    }, "Radio Frequencies");

    current_y += 20.0 * config.scale; // Group padding
    for (bounds_ptrs) |bound| {
        bound.y = current_y;
    }

    // UHF Row
    _ = rg.guiLabel(.{ .x = config.base_x, .y = current_y, .width = config.freq_width, .height = config.element_height }, "UHF Freq:");
    const uhf_hover = InputBox.handleInputBox(.{
        .buffer = &state.uhf_freq,
        .len = &state.uhf_freq_len,
        .is_editing = &state.uhf_edit,
        .bounds = textbox_bounds,
    });
    _ = rg.guiButton(button_bounds, "Change FRQ");
    _ = rg.guiSlider(slider_bounds, "Vol:", "", &state.uhf_vol, 0, 10);
    _ = rg.guiCheckBox(checkbox_bounds, "UHF Active (F1)", &state.uhf_active);

    current_y += config.element_height + config.margin;
    for (bounds_ptrs) |bound| {
        bound.y = current_y;
    }

    // VHF Row
    _ = rg.guiLabel(.{ .x = config.base_x, .y = current_y, .width = config.freq_width, .height = config.element_height }, "VHF Freq:");
    const vhf_hover = InputBox.handleInputBox(.{
        .buffer = &state.vhf_freq,
        .len = &state.vhf_freq_len,
        .is_editing = &state.vhf_edit,
        .bounds = textbox_bounds,
    });

    // Handle mutual exclusion of editing states
    if (rl.isMouseButtonPressed(.mouse_button_left)) {
        if (uhf_hover) {
            state.vhf_edit = false;
        } else if (vhf_hover) {
            state.uhf_edit = false;
        } else {
            state.uhf_edit = false;
            state.vhf_edit = false;
        }
    }

    // Reset cursor if not hovering over any input
    if (!uhf_hover and !vhf_hover) {
        rl.setMouseCursor(.mouse_cursor_default);
    }

    _ = rg.guiButton(button_bounds, "Change FRQ");
    _ = rg.guiSlider(slider_bounds, "Vol:", "", &state.vhf_vol, 0, 10);
    _ = rg.guiCheckBox(checkbox_bounds, "VHF Active (F2)", &state.vhf_active);

    current_y += config.element_height + config.margin;
    for (bounds_ptrs) |bound| {
        bound.y = current_y;
    }

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
        .x = config.base_x + config.group_width - (175.0 * config.scale),
        .y = current_y,
        .width = config.element_height,
        .height = config.element_height,
    }, "GUARD Active (F3)", &state.guard_active);
}
