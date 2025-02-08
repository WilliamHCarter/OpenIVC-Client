const std = @import("std");
const c = @cImport({
    @cInclude("miniaudio.h");
});

pub const SoundState = struct {
    context: c.ma_context,
    capture_devices: []c.ma_device_info,
    playback_devices: []c.ma_device_info,
    capture_device_index: i32 = 0,
    playback_device_index: i32 = 0,
    input_dropdown_open: bool = false,
    output_dropdown_open: bool = false,

    pub fn init(allocator: std.mem.Allocator) !SoundState {
        var context: c.ma_context = undefined;
        if (c.ma_context_init(null, 0, null, &context) != c.MA_SUCCESS) {
            return error.ContextInitFailed;
        }

        // Get device counts
        var capture_count: c.ma_uint32 = undefined;
        var playback_count: c.ma_uint32 = undefined;
        _ = c.ma_context_get_devices(&context, null, &playback_count, null, &capture_count);

        // Allocate and fetch device info
        var capture_devices = try allocator.alloc(c.ma_device_info, capture_count);
        var playback_devices = try allocator.alloc(c.ma_device_info, playback_count);

        _ = c.ma_context_get_devices(&context, playback_devices.ptr, &playback_count, capture_devices.ptr, &capture_count);

        return SoundState{
            .context = context,
            .capture_devices = capture_devices,
            .playback_devices = playback_devices,
            .capture_device_index = 0,
            .playback_device_index = 0,
            .input_dropdown_open = false,
            .output_dropdown_open = false,
        };
    }

    pub fn deinit(self: *SoundState, allocator: std.mem.Allocator) void {
        allocator.free(self.capture_devices);
        allocator.free(self.playback_devices);
        _ = c.ma_context_uninit(&self.context);
    }
};
