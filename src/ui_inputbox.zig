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

    _ = rg.guiTextBox(state.bounds, @ptrCast(&state.buffer[0]), @intCast(state.len.* + 1), state.is_editing.*);
    return mouse_on_input;
}
