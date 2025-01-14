const rl = @import("raylib");
const rg = @import("raygui");

pub const SoundState = struct {
    capture_device_index: i32 = 0,
    playback_device_index: i32 = 0,
    input_dropdown_open: bool = false,
    output_dropdown_open: bool = false,
};

pub const DrawConfig = struct {
    base_x: f32,
    start_y: f32,
    group_width: f32,
    element_height: f32,
    label_width: f32,
    margin: f32,
    scale: f32,
};

// Returns the final Y position after drawing
pub fn drawSoundGroup(config: DrawConfig) void {
    const state = SoundState{};
    var current_y = config.start_y;

    // Draw the group box
    _ = rg.guiGroupBox(.{
        .x = (@as(f32, @floatFromInt(rl.getScreenWidth())) - config.group_width) / 2,
        .y = current_y,
        .width = config.group_width,
        .height = 100.0 * config.scale,
    }, "Sound Devices");

    current_y += 20.0 * config.scale; // Group padding

    // Capture device section
    var label_bounds = rl.Rectangle.init(config.base_x, current_y, config.label_width, config.element_height);
    _ = rg.guiLabel(label_bounds, "Capture:");

    // Capture dropdown
    const input_dropdown_bounds = rl.Rectangle{
        .x = config.base_x,
        .y = current_y + config.element_height,
        .width = (config.group_width / 2) - (config.margin * 3),
        .height = config.element_height,
    };

    // Draw the capture dropdown and handle click
    const in_res = rg.guiDropdownBox(input_dropdown_bounds, "Analogue 1+2;USB Device 1;Default Input", &state.capture_device_index, state.input_dropdown_open);
    if (in_res == 1) {
        state.input_dropdown_open = !state.input_dropdown_open;
    }

    // Playback device section
    label_bounds.x = config.base_x + (config.group_width / 2);
    _ = rg.guiLabel(label_bounds, "Playback:");

    // Playback dropdown
    const output_dropdown_bounds = rl.Rectangle{
        .x = config.base_x + (config.group_width / 2) - config.margin,
        .y = current_y + config.element_height,
        .width = (config.group_width / 2) - (config.margin * 3),
        .height = config.element_height,
    };

    // Draw the playback dropdown and handle click
    const out_res = rg.guiDropdownBox(output_dropdown_bounds, "Default Output;Speakers;Headphones", &state.playback_device_index, state.output_dropdown_open);
    if (out_res == 1) {
        state.output_dropdown_open = !state.output_dropdown_open;
    }
}
