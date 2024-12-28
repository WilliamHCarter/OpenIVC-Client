const rl = @import("raylib");
const rg = @import("raygui");

pub const ServerState = struct {
    nickname_buf: [128]u8,
    server_ip_buf: [128]u8,
    connection_status_buf: [128]u8,
    connected: bool = false,
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
pub fn drawServerGroup(state: *ServerState, config: DrawConfig) void {
    var label_bounds: rl.Rectangle = rl.Rectangle.init(config.base_x, config.start_y, config.group_width, config.element_height);
    var text_bounds: rl.Rectangle = rl.Rectangle.init(config.base_x + config.label_width * 1.4, config.start_y, config.input_width, config.element_height);
    const button_bounds: rl.Rectangle = rl.Rectangle.init(config.base_x + config.label_width * 1.4 + config.input_width + config.margin, config.start_y + 2 * (config.element_height + config.margin), config.button_width, config.element_height);

    _ = rg.guiGroupBox(.{
        .x = (@as(f32, @floatFromInt(rl.getScreenWidth())) - config.group_width) / 2,
        .y = config.margin * 4,
        .width = config.group_width,
        .height = 130.0 * config.scale,
    }, "Server Connection");

    // Server connection controls
    _ = rg.guiLabel(label_bounds, "Nickname:");
    _ = rg.guiTextBox(text_bounds, @ptrCast(&state.nickname_buf), 14, true);
    label_bounds.y += config.element_height + config.margin;
    text_bounds.y += config.element_height + config.margin;

    _ = rg.guiLabel(label_bounds, "Server IP/DNS:");
    _ = rg.guiTextBox(text_bounds, @ptrCast(&state.server_ip_buf), 14, true);
    label_bounds.y += config.element_height + config.margin;
    text_bounds.y += config.element_height + config.margin;

    _ = rg.guiLabel(label_bounds, "Connection Status:");
    _ = rg.guiTextBox(text_bounds, @ptrCast(&state.connection_status_buf), 14, false);
    _ = rg.guiButton(button_bounds, "Disconnect");
}
