const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const SoundState = @import("../sound_state.zig").SoundState;
const SoundDevice = @import("../sound_state.zig").SoundDevice;
pub const DrawConfig = struct {
    base_x: f32,
    start_y: f32,
    group_width: f32,
    element_height: f32,
    label_width: f32,
    margin: f32,
    scale: f32,
};

fn buildDeviceList(devices: []const SoundDevice, allocator: std.mem.Allocator) ![:0]const u8 {
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    for (devices, 0..) |device, i| {
        try list.appendSlice(device.name);
        if (i < devices.len - 1) {
            try list.append(';');
        }
    }

    try list.append(0);
    const result = try list.toOwnedSlice();
    return result[0 .. result.len - 1 :0];
}

pub fn drawSoundGroup(sound_state: *SoundState, config: DrawConfig) !void {
    var current_y = config.start_y;

    // Draw the group box
    _ = rg.guiGroupBox(.{
        .x = (@as(f32, @floatFromInt(rl.getScreenWidth())) - config.group_width) / 2,
        .y = current_y,
        .width = config.group_width,
        .height = 100.0 * config.scale,
    }, "Sound Devices");

    current_y += 20.0 * config.scale;

    // Capture device section
    var label_bounds = rl.Rectangle.init(config.base_x, current_y, config.label_width, config.element_height);
    _ = rg.guiLabel(label_bounds, "Capture:");

    // Build device lists
    const capture_list = try buildDeviceList(sound_state.capture_devices, sound_state.allocator);
    defer sound_state.allocator.free(capture_list);
    const playback_list = try buildDeviceList(sound_state.playback_devices, sound_state.allocator);
    defer sound_state.allocator.free(playback_list);

    // Convert selection indices for GUI
    var selected_capture = @as(i32, @intCast(sound_state.selected_capture));
    var selected_playback = @as(i32, @intCast(sound_state.selected_playback));

    // Capture dropdown
    const input_dropdown_bounds = rl.Rectangle{
        .x = config.base_x,
        .y = current_y + config.element_height,
        .width = (config.group_width / 2) - (config.margin * 3),
        .height = config.element_height,
    };

    // Draw the capture dropdown and handle click
    const in_res = rg.guiDropdownBox(input_dropdown_bounds, capture_list.ptr, &selected_capture, sound_state.ui_state.input_dropdown_open);

    if (in_res == 1) {
        sound_state.ui_state.input_dropdown_open = !sound_state.ui_state.input_dropdown_open;
        if (!sound_state.ui_state.input_dropdown_open) {
            sound_state.selected_capture = @intCast(selected_capture);
            try sound_state.updateCaptureDevice();
        }
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
    const out_res = rg.guiDropdownBox(output_dropdown_bounds, playback_list.ptr, &selected_playback, sound_state.ui_state.output_dropdown_open);

    if (out_res == 1) {
        sound_state.ui_state.output_dropdown_open = !sound_state.ui_state.output_dropdown_open;
        if (!sound_state.ui_state.output_dropdown_open) {
            sound_state.selected_playback = @intCast(selected_playback);
            try sound_state.updatePlaybackDevice();
        }
    }

    // Close dropdowns when clicking outside
    if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
        const mouse_pos = rl.getMousePosition();
        if (!rl.checkCollisionPointRec(mouse_pos, input_dropdown_bounds) and
            !rl.checkCollisionPointRec(mouse_pos, output_dropdown_bounds))
        {
            sound_state.ui_state.input_dropdown_open = false;
            sound_state.ui_state.output_dropdown_open = false;
        }
    }
}
