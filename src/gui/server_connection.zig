const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const InputBox = @import("ui_inputbox.zig");

pub const ServerState = struct {
    nickname_buf: [128]u8 = "Micro                                                                                                                           ".*,
    server_ip_buf: [128]u8 = "5.9.54.24                                                                                                                       ".*,
    connection_status_buf: [128]u8 = "Connected                                                                                                                       ".*,
    nickname_len: usize = 5,
    server_ip_len: usize = 9,
    connected: bool = false,
    nickname_edit: bool = false,
    server_ip_edit: bool = false,
};

pub const DrawConfig = struct {
    base_x: f32,
    start_y: f32,
    group_width: f32,
    element_height: f32,
    label_width: f32,
    input_width: f32,
    button_width: f32,
    margin: f32,
    scale: f32,
};

pub fn drawServerGroup(config: DrawConfig) void {
    const state = ServerState{};
    var label_bounds = rl.Rectangle.init(config.base_x, config.start_y, config.group_width, config.element_height);
    var text_bounds = rl.Rectangle.init(config.base_x + config.label_width * 1.4, config.start_y, config.input_width, config.element_height);

    // Group box setup
    _ = rg.guiGroupBox(.{
        .x = (@as(f32, @floatFromInt(rl.getScreenWidth())) - config.group_width) / 2,
        .y = config.margin * 4,
        .width = config.group_width,
        .height = 130.0 * config.scale,
    }, "Server Connection");

    // Nickname input
    _ = rg.guiLabel(label_bounds, "Nickname:");
    const nickname_hover = InputBox.handleInputBox(.{
        .buffer = &state.nickname_buf,
        .len = &state.nickname_len,
        .is_editing = &state.nickname_edit,
        .bounds = text_bounds,
    });

    // Update positions for next row
    label_bounds.y += config.element_height + config.margin;
    text_bounds.y += config.element_height + config.margin;

    _ = rg.guiLabel(label_bounds, "Server IP/DNS:");
    const server_ip_hover = InputBox.handleInputBox(.{
        .buffer = &state.server_ip_buf,
        .len = &state.server_ip_len,
        .is_editing = &state.server_ip_edit,
        .bounds = text_bounds,
    });

    if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
        if (nickname_hover) {
            state.server_ip_edit = false;
        } else if (server_ip_hover) {
            state.nickname_edit = false;
        } else {
            state.nickname_edit = false;
            state.server_ip_edit = false;
        }
    }

    if (!nickname_hover and !server_ip_hover) {
        rl.setMouseCursor(rl.MouseCursor.default);
    }

    label_bounds.y += config.element_height + config.margin;
    text_bounds.y += config.element_height + config.margin;

    _ = rg.guiLabel(label_bounds, "Connection Status:");
    _ = rg.guiTextBox(text_bounds, @ptrCast(&state.connection_status_buf), 14, false);

    const button_bounds = rl.Rectangle.init(config.base_x + config.label_width * 1.4 + config.input_width + config.margin, config.start_y + 2 * (config.element_height + config.margin), config.button_width, config.element_height);

    const button_pressed = rg.guiButton(button_bounds, if (state.connected) "Disconnect" else "Connect");
    if (button_pressed == 1) {
        state.connected = !state.connected;
    }
}
