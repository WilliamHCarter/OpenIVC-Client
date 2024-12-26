const rl = @import("raylib");
const rg = @import("raygui");

pub const ServerState = struct {
    nickname_buf: [128]u8,
    server_ip_buf: [128]u8,
    connection_status_buf: [128]u8,
    connected: bool = false,
};

pub const DrawConfig = struct {
    base_x: i32,
    start_y: i32,
    group_width: i32,
    element_height: i32,
    label_width: i32,
    input_width: i32,
    button_width: i32,
    margin: i32,
    scale: f32,
};

pub fn drawServerGroup(state: *ServerState, config: DrawConfig) void {
    var current_y = config.start_y;
    const serverGroupY = config.margin * 4;
    _ = rg.guiGroupBox(.{
        .x = @floatFromInt(@divTrunc((rl.getScreenWidth() - config.group_width), 2)),
        .y = @floatFromInt(serverGroupY),
        .width = @floatFromInt(config.group_width),
        .height = 130.0 * config.scale,
    }, "Server Connection");

    // Server connection controls
    _ = rg.guiLabel(.{ .x = @floatFromInt(config.base_x), .y = @floatFromInt(current_y), .width = @floatFromInt(config.label_width), .height = @floatFromInt(config.element_height) }, "Nickname:");
    _ = rg.guiTextBox(.{ .x = @floatFromInt(config.base_x + config.label_width), .y = @floatFromInt(current_y), .width = @floatFromInt(config.input_width), .height = @floatFromInt(config.element_height) }, @ptrCast(&state.nickname_buf), 14, true);
    current_y += config.element_height + config.margin;

    _ = rg.guiLabel(.{ .x = @floatFromInt(config.base_x), .y = @floatFromInt(current_y), .width = @floatFromInt(config.label_width), .height = @floatFromInt(config.element_height) }, "Server IP/DNS:");
    _ = rg.guiTextBox(.{ .x = @floatFromInt(config.base_x + config.label_width), .y = @floatFromInt(current_y), .width = @floatFromInt(config.input_width), .height = @floatFromInt(config.element_height) }, @ptrCast(&state.server_ip_buf), 14, true);
    current_y += config.element_height + config.margin;

    _ = rg.guiLabel(.{ .x = @floatFromInt(config.base_x), .y = @floatFromInt(current_y), .width = @floatFromInt(config.label_width), .height = @floatFromInt(config.element_height) }, "Connection Status:");
    _ = rg.guiTextBox(.{ .x = @floatFromInt(config.base_x + config.label_width), .y = @floatFromInt(current_y), .width = @floatFromInt(config.input_width), .height = @floatFromInt(config.element_height) }, @ptrCast(&state.connection_status_buf), 14, false);
    _ = rg.guiButton(.{ .x = @floatFromInt(config.base_x + config.label_width + config.input_width + config.margin), .y = @floatFromInt(current_y), .width = @floatFromInt(config.button_width), .height = @floatFromInt(config.element_height) }, "Disconnect");
}
