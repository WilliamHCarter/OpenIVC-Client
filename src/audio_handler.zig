// audio_handler.zig
const std = @import("std");
const c = @cImport({
    @cInclude("miniaudio.h");
});

pub const AudioConfig = struct {
    sample_rate: u32 = 48000,
    channels: u32 = 2,
    buffer_frame_size: u32 = 480,
};

pub const AudioHandler = struct {
    config: AudioConfig,
    capture_device: c.ma_device,
    playback_device: c.ma_device,
    ring_buffer: c.ma_rb,
    buffer_data: []u8,
    allocator: std.mem.Allocator,
    is_running: bool,

    pub fn init(allocator: std.mem.Allocator, config: AudioConfig) !*AudioHandler {
        const self = try allocator.create(AudioHandler);
        errdefer allocator.destroy(self);

        const buffer_size = config.buffer_frame_size * config.channels * @sizeOf(f32);
        const buffer_data = try allocator.alloc(u8, buffer_size * 4);
        errdefer allocator.free(buffer_data);

        self.* = .{
            .config = config,
            .capture_device = undefined,
            .playback_device = undefined,
            .ring_buffer = undefined,
            .buffer_data = buffer_data,
            .allocator = allocator,
            .is_running = false,
        };

        // Initialize ring buffer
        if (c.ma_rb_init(
            buffer_size,
            buffer_data.ptr,
            null,
            null,
            &self.ring_buffer,
        ) != c.MA_SUCCESS) {
            return error.RingBufferInitFailed;
        }

        try self.initDevices();
        return self;
    }

    fn initDevices(self: *AudioHandler) !void {
        // Configure capture device
        var capture_config = c.ma_device_config_init(c.ma_device_type_capture);
        capture_config.capture.format = c.ma_format_f32;
        capture_config.capture.channels = @intCast(self.config.channels);
        capture_config.sampleRate = self.config.sample_rate;
        capture_config.dataCallback = captureCallback;
        capture_config.pUserData = self;

        if (c.ma_device_init(null, &capture_config, &self.capture_device) != c.MA_SUCCESS) {
            return error.CaptureDeviceInitFailed;
        }

        // Configure playback device
        var playback_config = c.ma_device_config_init(c.ma_device_type_playback);
        playback_config.playback.format = c.ma_format_f32;
        playback_config.playback.channels = @intCast(self.config.channels);
        playback_config.sampleRate = self.config.sample_rate;
        playback_config.dataCallback = playbackCallback;
        playback_config.pUserData = self;

        if (c.ma_device_init(null, &playback_config, &self.playback_device) != c.MA_SUCCESS) {
            return error.PlaybackDeviceInitFailed;
        }
    }

    pub fn start(self: *AudioHandler) !void {
        if (c.ma_device_start(&self.capture_device) != c.MA_SUCCESS) {
            return error.StartCaptureFailed;
        }
        if (c.ma_device_start(&self.playback_device) != c.MA_SUCCESS) {
            _ = c.ma_device_stop(&self.capture_device);
            return error.StartPlaybackFailed;
        }
        self.is_running = true;
    }

    pub fn stop(self: *AudioHandler) void {
        if (self.is_running) {
            _ = c.ma_device_stop(&self.capture_device);
            _ = c.ma_device_stop(&self.playback_device);
            self.is_running = false;
        }
    }

    pub fn deinit(self: *AudioHandler) void {
        self.stop();
        c.ma_device_uninit(&self.capture_device);
        c.ma_device_uninit(&self.playback_device);
        c.ma_rb_uninit(&self.ring_buffer);
        self.allocator.free(self.buffer_data);
        self.allocator.destroy(self);
    }

    fn captureCallback(
        device: [*c]c.ma_device,
        output: ?*anyopaque,
        input: ?*const anyopaque,
        frameCount: c.ma_uint32,
    ) callconv(.C) void {
        _ = output;
        const self = @ptrCast(*AudioHandler, @alignCast(@alignOf(*AudioHandler), device.*.pUserData));
        const bytes_to_write = frameCount * device.*.capture.channels * @sizeOf(f32);

        _ = c.ma_rb_write(&self.ring_buffer, input, bytes_to_write);
    }

    fn playbackCallback(
        device: [*c]c.ma_device,
        output: ?*anyopaque,
        input: ?*const anyopaque,
        frameCount: c.ma_uint32,
    ) callconv(.C) void {
        _ = input;
        const self = @ptrCast(*AudioHandler, @alignCast(@alignOf(*AudioHandler), device.*.pUserData));
        const bytes_to_read = frameCount * device.*.playback.channels * @sizeOf(f32);

        const bytes_read = c.ma_rb_read(&self.ring_buffer, output, bytes_to_read);
        if (bytes_read < bytes_to_read) {
            // Fill remaining buffer with silence if we don't have enough data
            const remaining = @ptrCast([*]u8, @alignCast(@alignOf(u8), output.?)) + bytes_read;
            @memset(remaining, 0, bytes_to_read - bytes_read);
        }
    }

    pub fn updateCaptureDevice(self: *AudioHandler, device_info: *const c.ma_device_info) !void {
        self.stop();
        var config = c.ma_device_config_init(c.ma_device_type_capture);
        config.capture.pDeviceID = &device_info.id;
        config.capture.format = c.ma_format_f32;
        config.capture.channels = @intCast(self.config.channels);
        config.sampleRate = self.config.sample_rate;
        config.dataCallback = captureCallback;
        config.pUserData = self;

        c.ma_device_uninit(&self.capture_device);
        if (c.ma_device_init(null, &config, &self.capture_device) != c.MA_SUCCESS) {
            return error.CaptureDeviceInitFailed;
        }
        try self.start();
    }

    pub fn updatePlaybackDevice(self: *AudioHandler, device_info: *const c.ma_device_info) !void {
        self.stop();
        var config = c.ma_device_config_init(c.ma_device_type_playback);
        config.playback.pDeviceID = &device_info.id;
        config.playback.format = c.ma_format_f32;
        config.playback.channels = @intCast(self.config.channels);
        config.sampleRate = self.config.sample_rate;
        config.dataCallback = playbackCallback;
        config.pUserData = self;

        c.ma_device_uninit(&self.playback_device);
        if (c.ma_device_init(null, &config, &self.playback_device) != c.MA_SUCCESS) {
            return error.PlaybackDeviceInitFailed;
        }
        try self.start();
    }
};
