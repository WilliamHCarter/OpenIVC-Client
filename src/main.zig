const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");

// Define available themes
const Theme = enum(i32) {
    Default = 0,
    Dark,
    Jungle,
    Candy,
    Cherry,
    Cyber,
};

pub fn loadTheme(theme: Theme) void {
    if (theme == .Default) {
        rg.guiLoadStyleDefault();
    } else {
        const path = switch (theme) {
            .Default => unreachable,
            .Dark => "src/styles/style_dark.rgs",
            .Jungle => "src/styles/style_jungle.rgs",
            .Candy => "src/styles/style_candy.rgs",
            .Cherry => "src/styles/style_cherry.rgs",
            .Cyber => "src/styles/style_cyber.rgs",
        };

        // Try to open the file to verify it exists
        const file = std.fs.cwd().openFile(path, .{}) catch |err| {
            std.debug.print("Error opening style file {s}: {any}\n", .{ path, err });
            return;
        };
        defer file.close();

        std.debug.print("Successfully opened style file: {s}\n", .{path});
        rg.guiLoadStyle(path);
    }
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    // Enable window resizing before initialization
    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "OpenIVC Client");
    defer rl.closeWindow();

    // Remove FPS cap by setting it to 0
    rl.setTargetFPS(0);

    // GUI state variables
    var sliderValue: f32 = 50.0;
    var checkBoxChecked = false;
    var dropDownIndex: i32 = 0;
    var spinnerValue: i32 = 0;
    var themeIndex: i32 = 0;
    var previousThemeIndex: i32 = -1; // Track theme changes

    // Load initial theme
    loadTheme(.Default);

    //--------------------------------------------------------------------------------------
    // Main game loop
    while (!rl.windowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        const currentWidth = rl.getScreenWidth();
        const currentHeight = rl.getScreenHeight();

        // Calculate scaling factors
        const scaleX = @as(f32, @floatFromInt(currentWidth)) / @as(f32, @floatFromInt(screenWidth));
        const scaleY = @as(f32, @floatFromInt(currentHeight)) / @as(f32, @floatFromInt(screenHeight));
        const scale = @min(scaleX, scaleY);

        // Calculate base positions and sizes
        const baseWidth = @as(i32, @intFromFloat(200.0 * scale));
        const baseHeight = @as(i32, @intFromFloat(20.0 * scale));
        const centerX = @divTrunc(currentWidth, 2);
        const spacing = @as(i32, @intFromFloat(40.0 * scale));

        // Check if theme changed
        if (themeIndex != previousThemeIndex) {
            loadTheme(@as(Theme, @enumFromInt(themeIndex)));
            previousThemeIndex = themeIndex;
        }

        //----------------------------------------------------------------------------------
        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        // Theme selector
        const themeDropdownWidth = @as(i32, @intFromFloat(150.0 * scale)); // Slightly smaller than other elements
        const themeDropdownHeight = @as(i32, @intFromFloat(20.0 * scale));
        const margin = @as(i32, @intFromFloat(10.0 * scale)); // Margin from screen edge

        _ = rg.guiDropdownBox(.{
            .x = @floatFromInt(currentWidth - themeDropdownWidth - margin),
            .y = @floatFromInt(margin), // Same height as FPS counter
            .width = @floatFromInt(themeDropdownWidth),
            .height = @floatFromInt(themeDropdownHeight),
        }, "Default;Dark;Jungle;Candy;Cherry;Cyber", &themeIndex, true);
        // Draw GUI elements
        _ = rg.guiSliderBar(.{
            .x = @floatFromInt(centerX - @divFloor(baseWidth, 2)),
            .y = @floatFromInt(spacing * 2),
            .width = @floatFromInt(baseWidth),
            .height = @floatFromInt(baseHeight),
        }, "Slide me", "", &sliderValue, 0, 100);

        _ = rg.guiCheckBox(.{
            .x = @floatFromInt(centerX - @divFloor(baseWidth, 2)),
            .y = @floatFromInt(spacing * 3),
            .width = @floatFromInt(baseHeight),
            .height = @floatFromInt(baseHeight),
        }, "Check me", &checkBoxChecked);

        _ = rg.guiDropdownBox(.{
            .x = @floatFromInt(centerX - @divFloor(baseWidth, 2)),
            .y = @floatFromInt(spacing * 4),
            .width = @floatFromInt(baseWidth),
            .height = @floatFromInt(baseHeight),
        }, "Option 1;Option 2;Option 3", &dropDownIndex, true);

        _ = rg.guiSpinner(.{
            .x = @floatFromInt(centerX - @divFloor(baseWidth, 2)),
            .y = @floatFromInt(spacing * 5),
            .width = @floatFromInt(baseWidth),
            .height = @floatFromInt(baseHeight),
        }, "Spin me", &spinnerValue, 0, 100, true);

        // Display current FPS in top-left corner (scaled)
        const fontSize = @as(i32, @intFromFloat(20.0 * scale));
        const fps_text = rl.textFormat("FPS: %d", .{rl.getFPS()});
        rl.drawText(fps_text, 10, 10, fontSize, rl.Color.dark_gray);

        //----------------------------------------------------------------------------------
    }
}
