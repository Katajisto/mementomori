const r = @import("ray.zig").r;
const utils = @import("utils.zig");
const std = @import("std");
const fs = std.fs;

const SIDEBAR_SIZE = 400;

pub fn tof(x: i32) f32 {
    return @as(f32, @floatFromInt(x));
}

pub fn toi(x: f32) i32 {
    return @as(i32, @intFromFloat(x));
}

pub fn drawTexLetterboxed(tex: r.Texture2D, swidth: i32, sheight: i32) void {
    var trueWidth: f32 = tof(swidth) - SIDEBAR_SIZE;

    var imageAspect = tof(tex.width) / tof(tex.height);
    var screenAspect = trueWidth / tof(sheight);

    var renderWidth: f32 = 0;
    var renderHeight: f32 = 0;

    if (imageAspect > screenAspect) {
        renderHeight = trueWidth / imageAspect;
        renderWidth = trueWidth;
    } else {
        renderHeight = tof(sheight);
        renderWidth = tof(sheight) * imageAspect;
    }

    r.DrawTexturePro(tex, r.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(tex.width)), .height = @as(f32, @floatFromInt(tex.height)) }, r.Rectangle{ .x = SIDEBAR_SIZE, .y = 0, .width = renderWidth, .height = renderHeight }, r.Vector2{
        .x = 0,
        .y = 0,
    }, 0, r.WHITE);
}

pub fn calcImgSize(tex: r.Texture2D, swidth: i32, sheight: i32) r.Rectangle {
    var trueWidth: f32 = tof(swidth) - SIDEBAR_SIZE;

    var imageAspect = tof(tex.width) / tof(tex.height);
    var screenAspect = trueWidth / tof(sheight);

    var renderWidth: f32 = 0;
    var renderHeight: f32 = 0;

    if (imageAspect > screenAspect) {
        renderHeight = trueWidth / imageAspect;
        renderWidth = trueWidth;
    } else {
        renderHeight = tof(sheight);
        renderWidth = tof(sheight) * imageAspect;
    }

    return r.Rectangle{ .x = SIDEBAR_SIZE, .y = 0, .width = renderWidth, .height = renderHeight };
}

pub fn transformScreenCoordsToImageSpace(mousePos: r.Vector2, imgRect: r.Rectangle, tex: r.Texture2D) r.Vector2 {
    // Adjust the X coordinate by subtracting the sidebar size
    var adjustedScreenX = mousePos.x - SIDEBAR_SIZE;

    // Ensure that we do not transform coordinates that are within the sidebar area
    if (adjustedScreenX < 0) {
        adjustedScreenX = 0;
    }

    // Calculate the scale factors for width and height
    var scaleX: f32 = imgRect.width / imgRect.width;
    var scaleY: f32 = imgRect.height / imgRect.height;

    // Apply the scale factors and adjust for the position of the image (imgRect.x and imgRect.y)
    var imageX: f32 = adjustedScreenX / scaleX;
    var imageY: f32 = mousePos.y / scaleY;

    // Img relative, but at screen scale. Not good.
    var mults = r.Vector2{ .x = imageX / imgRect.width, .y = imageY / imgRect.height };
    return r.Vector2{ .x = tof(tex.width) * mults.x, .y = tof(tex.height) * mults.y };
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var screen_width: i32 = 1920;
    var screen_height: i32 = 1080;
    // r.SetTraceLogLevel(r.LOG_ERROR);
    r.InitWindow(screen_width, screen_height, "Memento mori");

    try utils.printIntro();

    var cwd = fs.cwd();
    var uudet = try cwd.openIterableDir("uudet", .{});

    var walker = try uudet.walk(allocator);
    defer walker.deinit();

    var texList = std.ArrayList(r.Texture2D).init(allocator);
    var imgList = std.ArrayList(r.Image).init(allocator);
    var rectList = std.ArrayList(r.Rectangle).init(allocator);
    defer rectList.deinit();
    defer texList.deinit();
    defer imgList.deinit();

    r.SetTargetFPS(60);
    r.GuiSetStyle(r.DEFAULT, r.TEXT_SIZE, 25);
    r.GuiSetStyle(r.DEFAULT, r.TEXT_ALIGNMENT, r.TEXT_ALIGN_CENTER);

    var rectStart: ?r.Vector2 = null;

    var walkcount: usize = 0;
    while (try walker.next()) |entry| {
        if (walkcount > 99) {
            continue;
        }
        std.debug.print("{s}", .{entry.path});
        var fullPath = try std.fmt.allocPrint(allocator, "{s}{s}", .{ "./uudet/", entry.path });
        texList.append(r.LoadTexture(@as([*c]const u8, @ptrCast(fullPath)))) catch unreachable;
        walkcount += 1;
        allocator.free(fullPath);
    }

    var doExport = false;

    while (!r.WindowShouldClose()) {
        var texture = texList.items[0];
        var mp = r.GetMousePosition();
        var imgMp = transformScreenCoordsToImageSpace(mp, calcImgSize(texture, screen_width, screen_height), texture);

        std.debug.print("{d}:{d} \n", .{ imgMp.x, imgMp.y });

        if (doExport) {
            doExport = false;
            var img = r.LoadImageFromScreen();
            r.ImageCrop(&img, calcImgSize(texture, screen_width, screen_height));
            _ = r.ExportImage(img, "./export.png");
        }
        if (r.IsMouseButtonDown(0)) {
            if (rectStart == null) {
                rectStart = r.GetMousePosition();
            }
        } else {
            if (rectStart != null) {
                var mouseP = r.GetMousePosition();
                var mouseDiff = r.Vector2Subtract(mouseP, rectStart.?);
                if ((mouseDiff.x > 0 and mouseDiff.y > 0) or (mouseDiff.x < 0 and mouseDiff.y < 0)) {
                    rectList.append(.{ .x = rectStart.?.x, .y = rectStart.?.y, .width = mouseDiff.x, .height = mouseDiff.y }) catch unreachable;
                }
                rectStart = null;
            }
        }
        r.BeginDrawing();
        defer r.EndDrawing();
        r.ClearBackground(r.WHITE);
        _ = r.GuiLabel(.{ .x = 10, .y = 10, .width = 380, .height = 40 }, "Jennin Anki työkalu");
        if (r.GuiButton(.{ .x = 10, .y = 60, .width = 380, .height = 40 }, "Vie pakka") == 1) {
            doExport = true;
        }
        if (r.GuiButton(.{ .x = 10, .y = 120, .width = 380, .height = 40 }, "Poista viimeinen suorakulmio") == 1) {
            if (rectList.items.len > 0) {
                _ = rectList.orderedRemove(rectList.items.len - 1);
            }
        }
        drawTexLetterboxed(texture, screen_width, screen_height);
        if (rectStart != null) {
            var mouseP = r.GetMousePosition();
            var mouseDiff = r.Vector2Subtract(mouseP, rectStart.?);
            r.DrawRectangle(toi(rectStart.?.x), toi(rectStart.?.y), toi(mouseDiff.x), toi(mouseDiff.y), r.RED);
        }

        for (rectList.items) |rect| {
            r.DrawRectangle(toi(rect.x), toi(rect.y), toi(rect.width), toi(rect.height), r.BLUE);
        }
    }

    // Free
    for (texList) |tex| {
        r.UnloadTexture(tex);
    }
    for (imgList) |img| {
        r.UnloadImage(img);
    }

    defer r.CloseWindow(); // Close window and OpenGL context
}
