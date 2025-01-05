const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");

pub const InputBoxState = struct {
    buffer: []u8,
    len: *usize,
    is_editing: *bool,
    bounds: rl.Rectangle,
};

pub fn handleInputBox(state: InputBoxState) bool {
    const mouse_pos = rl.getMousePosition();
    const mouse_on_input = rl.checkCollisionPointRec(mouse_pos, state.bounds);

    // Handle click activation
    if (mouse_on_input and rl.isMouseButtonPressed(.mouse_button_left)) {
        state.is_editing.* = true;
        rl.setMouseCursor(.mouse_cursor_ibeam);
        return true;
    }

    // Handle deactivation when clicking outside
    if (rl.isMouseButtonPressed(.mouse_button_left) and !mouse_on_input) {
        state.is_editing.* = false;
        rl.setMouseCursor(.mouse_cursor_default);
    }

    // Handle text input when active
    if (state.is_editing.*) {
        var key = rl.getCharPressed();
        while (key > 0) : (key = rl.getCharPressed()) {
            // Only allow printable ASCII characters
            if (key >= 32 and key <= 125 and state.len.* < state.buffer.len - 1) {
                state.buffer[state.len.*] = @intCast(key);
                state.len.* += 1;
                state.buffer[state.len.*] = 0;
            }
        }

        // Handle backspace
        if (rl.isKeyPressed(.key_backspace) and state.len.* > 0) {
            state.len.* -= 1;
            state.buffer[state.len.*] = 0;
        }
    }

    // Draw the box
    const border_color = if (state.is_editing.*) rl.Color.dark_gray else rl.Color.light_gray;
    rl.drawRectangleLinesEx(state.bounds, 1, border_color);

    // Draw the text with padding
    const padding: f32 = 4;
    const text_pos = rl.Vector2{
        .x = state.bounds.x + padding,
        .y = state.bounds.y + (state.bounds.height - 20) * 0.5,
    };
    _ = rg.guiLabel(state.bounds, @ptrCast(&state.buffer[0]));

    // Draw cursor when editing
    if (state.is_editing.*) {
        const text_width = rl.measureText(@ptrCast(&state.buffer[0]), 20);
        const cursor_x = text_pos.x + @as(f32, @floatFromInt(text_width));
        const cursor_y = text_pos.y;
        const cursor_height: f32 = 20;
        rl.drawLineV(.{ .x = cursor_x, .y = cursor_y }, .{ .x = cursor_x, .y = cursor_y + cursor_height }, rl.Color.black);
    }

    return mouse_on_input;
}
