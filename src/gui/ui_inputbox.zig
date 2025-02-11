const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");

pub const InputBoxState = struct {
    buffer: [128]u8,
    len: *usize,
    is_editing: *bool,
    bounds: rl.Rectangle,
};

pub fn handleInputBox(state: InputBoxState) bool {
    const mouse_pos = rl.getMousePosition();
    const mouse_on_input = rl.checkCollisionPointRec(mouse_pos, state.bounds);

    // Handle click activation
    if (mouse_on_input and rl.isMouseButtonPressed(rl.MouseButton.left)) {
        state.is_editing.* = true;
        rl.setMouseCursor(rl.MouseCursor.ibeam);
        return true;
    }

    // Handle deactivation when clicking outside
    if (rl.isMouseButtonPressed(rl.MouseButton.left) and !mouse_on_input) {
        state.is_editing.* = false;
        rl.setMouseCursor(rl.MouseCursor.default);
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
        if (rl.isKeyPressed(rl.KeyboardKey.backspace) and state.len.* > 0) {
            state.len.* -= 1;
            state.buffer[state.len.*] = 0;
        }
    }

    // Draw the box
    const border_color = if (state.is_editing.*) rl.Color.dark_gray else rl.Color.light_gray;
    rl.drawRectangleLinesEx(state.bounds, 1, border_color);
    var label_bounds: rl.Rectangle = state.bounds;
    label_bounds.x += 5;
    _ = rg.guiLabel(label_bounds, @ptrCast(&state.buffer[0]));

    return mouse_on_input;
}
