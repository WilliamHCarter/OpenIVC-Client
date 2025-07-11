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

    // Audio level monitoring
    capture_level: f32,
    playback_level: f32,
    level_lock: std.Thread.Mutex,

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
            .capture_level = 0.0,
            .playback_level = 0.0,
            .level_lock = .{},
        };

        // Initialize ring buffer
        if (c.ma_rb_init(
            buffer_size,
            buffer_data.ptr,
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
        const self: *AudioHandler = @ptrCast(@alignCast(device.*.pUserData));
        const bytes_to_write: usize = frameCount * device.*.capture.channels * @sizeOf(f32);

        // Calculate RMS level for capture
        const samples: [*]const f32 = @ptrCast(@alignCast(input.?));
        const sample_count = frameCount * device.*.capture.channels;
        var sum: f32 = 0.0;
        var peak: f32 = 0.0;
        var i: usize = 0;

        while (i < sample_count) : (i += 1) {
            const sample = @abs(samples[i]);
            peak = @max(peak, sample);
            sum += sample * sample;
        }
        self.level_lock.lock();

        if (peak > self.capture_level) {
            self.capture_level = peak;
        } else {
            self.capture_level *= 0.95;
        }

        self.level_lock.unlock();

        var write_size = bytes_to_write;
        var write_buffer: ?*anyopaque = undefined;

        if (c.ma_rb_acquire_write(&self.ring_buffer, &write_size, &write_buffer) == c.MA_SUCCESS) {
            if (write_size > 0) {
                // Copy input data to ring buffer
                const src = @as([*]const u8, @ptrCast(input.?));
                const dst = @as([*]u8, @ptrCast(write_buffer.?));
                @memcpy(dst[0..write_size], src[0..write_size]);
            }
            _ = c.ma_rb_commit_write(&self.ring_buffer, write_size);
        }
    }

    fn playbackCallback(
        device: [*c]c.ma_device,
        output: ?*anyopaque,
        input: ?*const anyopaque,
        frameCount: c.ma_uint32,
    ) callconv(.C) void {
        _ = input;
        const self: *AudioHandler = @ptrCast(@alignCast(device.*.pUserData));
        const bytes_to_read: usize = frameCount * device.*.playback.channels * @sizeOf(f32);

        var read_size = bytes_to_read;
        var read_buffer: ?*anyopaque = undefined;
        var bytes_read: usize = 0;

        if (c.ma_rb_acquire_read(&self.ring_buffer, &read_size, &read_buffer) == c.MA_SUCCESS) {
            if (read_size > 0) {
                // Copy from ring buffer to output
                const src = @as([*]const u8, @ptrCast(read_buffer.?));
                const dst = @as([*]u8, @ptrCast(output.?));
                @memcpy(dst[0..read_size], src[0..read_size]);
                bytes_read = read_size;

                // Calculate RMS level for playback
                const samples: [*]const f32 = @ptrCast(@alignCast(output.?));
                const sample_count = read_size / @sizeOf(f32);
                var sum: f32 = 0.0;
                var i: usize = 0;
                while (i < sample_count) : (i += 1) {
                    sum += samples[i] * samples[i];
                }
                const rms = @sqrt(sum / @as(f32, @floatFromInt(sample_count)));

                // Update level with simple smoothing
                self.level_lock.lock();
                self.playback_level = self.playback_level * 0.9 + rms * 0.1;
                self.level_lock.unlock();
            }
            _ = c.ma_rb_commit_read(&self.ring_buffer, read_size);
        }

        // Fill remaining buffer with silence if we don't have enough data
        if (bytes_read < bytes_to_read) {
            const remaining = @as([*]u8, @ptrCast(output.?)) + bytes_read;
            @memset(remaining[0 .. bytes_to_read - bytes_read], 0);
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

    // Get current audio levels (0.0 to 1.0)
    pub fn getLevels(self: *AudioHandler) struct { capture: f32, playback: f32 } {
        self.level_lock.lock();
        defer self.level_lock.unlock();
        return .{
            .capture = @min(self.capture_level, 1.0),
            .playback = @min(self.playback_level, 1.0),
        };
    }

    // Convert linear level to dB
    pub fn levelToDb(level: f32) f32 {
        if (level <= 0.0) return -60.0;
        const db = 20.0 * @log10(level);
        return @max(db, -60.0);
    }
};
