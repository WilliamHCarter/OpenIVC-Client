const std = @import("std");
const c = @cImport({
    @cInclude("miniaudio.h");
});

pub const SoundDevice = struct {
    name: []const u8,
    info: c.ma_device_info,
};

pub const SoundState = struct {
    context: c.ma_context,
    capture_devices: []SoundDevice,
    playback_devices: []SoundDevice,
    selected_capture: usize,
    selected_playback: usize,
    ui_state: UiState,
    allocator: std.mem.Allocator,

    pub const UiState = struct {
        input_dropdown_open: bool = false,
        output_dropdown_open: bool = false,
    };

    pub fn init(allocator: std.mem.Allocator) !*SoundState {
        const self = try allocator.create(SoundState);

        if (c.ma_context_init(null, 0, null, &self.context) != c.MA_SUCCESS) {
            return error.ContextInitFailed;
        }

        // Initialize devices using the already-initialized context
        const capture_devs = try initDevices(allocator, &self.context, true);
        const playback_devs = try initDevices(allocator, &self.context, false);

        self.* = .{
            .context = self.context, // Keep the initialized context
            .capture_devices = capture_devs,
            .playback_devices = playback_devs,
            .selected_capture = 0,
            .selected_playback = 0,
            .ui_state = .{},
            .allocator = allocator,
        };

        return self;
    }

    fn initDevices(allocator: std.mem.Allocator, context: *c.ma_context, is_capture: bool) ![]SoundDevice {
        var count: c.ma_uint32 = undefined;
        var raw_devices: [*c]c.ma_device_info = undefined;

        // Get device count and info
        if (is_capture) {
            _ = c.ma_context_get_devices(context, null, null, &raw_devices, &count);
        } else {
            _ = c.ma_context_get_devices(context, &raw_devices, &count, null, null);
        }

        var devices = try allocator.alloc(SoundDevice, count);
        for (0..count) |i| {
            const name_ptr: [*:0]const u8 = @ptrCast(&raw_devices[i].name);

            devices[i] = .{
                .name = std.mem.span(name_ptr),
                .info = raw_devices[i],
            };
        }
        return devices;
    }

    pub fn deinit(self: *SoundState) void {
        self.allocator.free(self.capture_devices);
        self.allocator.free(self.playback_devices);
        _ = c.ma_context_uninit(&self.context);
        self.allocator.destroy(self);
    }

    pub fn updateCaptureDevice(self: *SoundState) !void {
        // TODO: Implement actual device switching logic
        std.debug.print("Selected capture device: {s}\n", .{self.capture_devices[self.selected_capture].name});
    }

    pub fn updatePlaybackDevice(self: *SoundState) !void {
        // TODO: Implement actual device switching logic
        std.debug.print("Selected playback device: {s}\n", .{self.playback_devices[self.selected_playback].name});
    }
};
