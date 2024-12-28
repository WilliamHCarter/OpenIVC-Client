const rl = @import("raylib");
const rg = @import("raygui");

pub const SoundState = struct {
    capture_device_index: i32 = 0,
    playback_device_index: i32 = 0,
    input_dropdown_open: bool = false,
    output_dropdown_open: bool = false,
};

pub const DrawConfig = struct {
    base_x: i32,
    start_y: i32,
    group_width: i32,
    element_height: i32,
    label_width: i32,
    margin: i32,
    scale: f32,
};

// Returns the final Y position after drawing
pub fn drawSoundGroup(state: *SoundState, config: DrawConfig) void {
    var current_y = config.start_y;

    // Draw the group box
    _ = rg.guiGroupBox(.{
        .x = @floatFromInt(@divTrunc((rl.getScreenWidth() - config.group_width), 2)),
        .y = @floatFromInt(current_y),
        .width = @floatFromInt(config.group_width),
        .height = 100.0 * config.scale,
    }, "Sound Devices");

    current_y += @as(i32, @intFromFloat(20.0 * config.scale)); // Group padding

    // Capture device section
    _ = rg.guiLabel(.{ .x = @floatFromInt(config.base_x), .y = @floatFromInt(current_y), .width = @floatFromInt(config.label_width), .height = @floatFromInt(config.element_height) }, "Capture:");

    // Capture dropdown
    const input_dropdown_bounds = rl.Rectangle{
        .x = @floatFromInt(config.base_x),
        .y = @floatFromInt(current_y + config.element_height),
        .width = @floatFromInt(@divTrunc(config.group_width, 2) - config.margin * 3),
        .height = @floatFromInt(config.element_height),
    };

    // Draw the capture dropdown and handle click
    const in_res = rg.guiDropdownBox(input_dropdown_bounds, "Analogue 1+2;USB Device 1;Default Input", &state.capture_device_index, state.input_dropdown_open);
    if (in_res == 1) {
        state.input_dropdown_open = !state.input_dropdown_open;
    }

    // Playback device section
    _ = rg.guiLabel(.{ .x = @floatFromInt(config.base_x + @divTrunc(config.group_width, 2)), .y = @floatFromInt(current_y), .width = @floatFromInt(config.label_width), .height = @floatFromInt(config.element_height) }, "Playback:");

    // Playback dropdown
    const output_dropdown_bounds = rl.Rectangle{
        .x = @floatFromInt(config.base_x + @divTrunc(config.group_width, 2) - config.margin),
        .y = @floatFromInt(current_y + config.element_height),
        .width = @floatFromInt(@divTrunc(config.group_width, 2) - config.margin * 3),
        .height = @floatFromInt(config.element_height),
    };

    // Draw the playback dropdown and handle click
    const out_res = rg.guiDropdownBox(output_dropdown_bounds, "Default Output;Speakers;Headphones", &state.playback_device_index, state.output_dropdown_open);
    if (out_res == 1) {
        state.output_dropdown_open = !state.output_dropdown_open;
    }
}
