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

        self.* = .{
            .context = undefined,
            .capture_devices = try initDevices(allocator, &self.context, true),
            .playback_devices = try initDevices(allocator, &self.context, false),
            .selected_capture = 0,
            .selected_playback = 0,
            .ui_state = .{},
            .allocator = allocator,
        };

        return self;
    }

    fn initDevices(allocator: std.mem.Allocator, context: *c.ma_context, is_capture: bool) ![]SoundDevice {
        var count: c.ma_uint32 = undefined;
        var raw_devices: []*c.ma_device_info = undefined;

        // Get device count and info
        if (is_capture) {
            _ = c.ma_context_get_devices(context, null, null, &raw_devices, &count);
        } else {
            _ = c.ma_context_get_devices(context, &raw_devices, &count, null, null);
        }

        var devices = try allocator.alloc(SoundDevice, count);
        for (raw_devices, 0..count) |device, i| {
            devices[i] = .{
                .name = std.mem.span(@as([*:0]const u8, &device.name)),
                .info = device.*,
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
};
