const r = @import("ray.zig").r;
const i = @import("image.zig");
const utils = @import("utils.zig");
const exporter = @import("export.zig");
const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var screen_width: i32 = 1080;
    var screen_height: i32 = 720;
    // r.SetTraceLogLevel(r.LOG_ERROR);
    r.SetConfigFlags(r.FLAG_WINDOW_RESIZABLE);
    r.InitWindow(screen_width, screen_height, "Jennin Anki työkalu v0.9");

    var conf = try utils.readConf(allocator);
    defer conf.deinit();

    var curImage: ?r.Image = null;
    var curTexture: ?r.Texture2D = null;

    var rectList = std.ArrayList(r.Rectangle).init(allocator);
    defer rectList.deinit();

    r.SetTargetFPS(60);
    r.GuiSetStyle(r.DEFAULT, r.TEXT_SIZE, 25);
    r.GuiSetStyle(r.DEFAULT, r.TEXT_ALIGNMENT, r.TEXT_ALIGN_CENTER);

    var rectStart: ?r.Vector2 = null;

    var doExport = false;
    var exportScreenFrames: i32 = 0;

    var transparencyMode = false;

    var filename = [_]u8{0} ** 100;

    while (!r.WindowShouldClose()) {
        var window_h = r.GetScreenHeight();
        var window_w = r.GetScreenWidth();
        std.debug.print("{d} {d}\n", .{ window_h, window_w });
        if (doExport and exportScreenFrames > 2) {
            exporter.exportImages(curImage.?, rectList, allocator, conf, @as([*:0]u8, @ptrCast(&filename)));
            doExport = false;
            r.UnloadImage(curImage.?);
            r.UnloadTexture(curTexture.?);
            curImage = null;
            curTexture = null;
            exportScreenFrames = 0;
            rectList.clearRetainingCapacity();
            filename = [_]u8{0} ** 100;
        }
        if (r.IsMouseButtonDown(0)) {
            if (rectStart == null) {
                rectStart = r.GetMousePosition();
            }
        } else {
            if (rectStart != null) {
                var mouseP = r.GetMousePosition();
                var mouseDiff = r.Vector2Subtract(mouseP, rectStart.?);
                var ok = true;
                // Do some checks:
                if (rectStart.?.x <= i.SIDEBAR_SIZE) {
                    ok = false;
                }

                if ((@abs(mouseDiff.x) * @abs(mouseDiff.y)) < 20) {
                    ok = false;
                }

                if (((mouseDiff.x > 0 and mouseDiff.y > 0) or (mouseDiff.x < 0 and mouseDiff.y < 0)) and ok) {
                    var curRectCorrectedStart = i.transformScreenCoordsToImageSpace(.{ .x = rectStart.?.x, .y = rectStart.?.y }, i.calcImgSize(curTexture.?, window_w, window_w), curTexture.?);
                    var curRectCorrectedEnd = i.transformScreenCoordsToImageSpace(.{ .x = rectStart.?.x + mouseDiff.x, .y = rectStart.?.y + mouseDiff.y }, i.calcImgSize(curTexture.?, window_w, window_w), curTexture.?);
                    var correctedSize = r.Vector2Subtract(curRectCorrectedEnd, curRectCorrectedStart);
                    rectList.append(.{ .x = curRectCorrectedStart.x, .y = curRectCorrectedStart.y, .width = correctedSize.x, .height = correctedSize.y }) catch unreachable;
                }
                if (!ok) {
                    std.debug.print("Rectangle was not ok", .{});
                }
                rectStart = null;
            }
        }
        r.BeginDrawing();
        defer r.EndDrawing();
        if (doExport) {
            r.ClearBackground(r.YELLOW);
            r.GuiSetStyle(r.DEFAULT, r.TEXT_SIZE, 50);
            _ = r.GuiLabel(.{ .x = 800, .y = 400, .height = 50, .width = 320 }, "Prosessoidaan...");
            r.GuiSetStyle(r.DEFAULT, r.TEXT_SIZE, 25);
            exportScreenFrames += 1;
        } else if (curImage != null and curTexture != null) {
            r.ClearBackground(r.WHITE);
            i.drawTexLetterboxed(curTexture.?, window_w, window_h);
            if (rectStart != null) {
                var mouseP = r.GetMousePosition();
                var mouseDiff = r.Vector2Subtract(mouseP, rectStart.?);
                r.DrawRectangle(i.toi(rectStart.?.x), i.toi(rectStart.?.y), i.toi(mouseDiff.x), i.toi(mouseDiff.y), r.RED);
            }

            for (rectList.items) |rect| {
                var rectColor = r.BLUE;
                if (transparencyMode) {
                    rectColor = r.Color{ .r = 0, .g = 0, .b = 255, .a = 60 };
                }
                var imgSize = i.calcImgSize(curTexture.?, window_w, window_h);
                var xOffset = (rect.x / i.tof(curTexture.?.width)) * imgSize.width + 400;
                var yOffset = (rect.y / i.tof(curTexture.?.height)) * imgSize.height;
                var xCorrected = (rect.width / i.tof(curTexture.?.width)) * imgSize.width;
                var yCorrected = (rect.height / i.tof(curTexture.?.height)) * imgSize.height;

                r.DrawRectangle(i.toi(xOffset), i.toi(yOffset), i.toi(xCorrected), i.toi(yCorrected), rectColor);
            }
            r.DrawRectangle(0, 0, 400, window_h, r.Color{ .r = 190, .g = 190, .b = 190, .a = 255 });
            _ = r.GuiLabel(.{ .x = 10, .y = 10, .width = 380, .height = 40 }, "Jennin Anki työkalu");
            if (r.GuiButton(.{ .x = 10, .y = i.tof(window_h) - 90, .width = 380, .height = 40 }, "Vie pakka") == 1 and filename[0] != 0) {
                doExport = true;
            }
            if (transparencyMode) {
                if (r.GuiButton(.{ .x = 10, .y = i.tof(window_h) - 200, .width = 380, .height = 40 }, "Tee laatikoista peittäviä") == 1) {
                    transparencyMode = false;
                }
            } else {
                if (r.GuiButton(.{ .x = 10, .y = i.tof(window_h) - 200, .width = 380, .height = 40 }, "Tee laatikoista läpinäkyviä") == 1) {
                    transparencyMode = true;
                }
            }
            if (r.GuiButton(.{ .x = 10, .y = i.tof(window_h) - 150, .width = 380, .height = 40 }, "Poista viimeinen suorakulmio") == 1) {
                if (rectList.items.len > 0) {
                    _ = rectList.orderedRemove(rectList.items.len - 1);
                }
            }

            _ = r.GuiLabel(.{ .x = 10, .y = 120, .height = 30, .width = 380 }, "Tiedostonimi");
            r.GuiSetStyle(r.DEFAULT, r.TEXT_ALIGNMENT, r.TEXT_ALIGN_LEFT);
            _ = r.GuiTextBox(.{ .x = 10, .y = 170, .width = 380, .height = 40 }, @as([*c]u8, @ptrCast(&filename)), 30, true);
            r.GuiSetStyle(r.DEFAULT, r.TEXT_ALIGNMENT, r.TEXT_ALIGN_CENTER);
            _ = r.GuiLabel(.{ .x = 10, .y = i.tof(window_h) - 32, .height = 30, .width = 380 }, "Katajisto 2023");
        } else {
            r.ClearBackground(r.RAYWHITE);
            if (r.IsFileDropped()) {
                var droppedFiles = r.LoadDroppedFiles();
                if (droppedFiles.count > 0) {
                    curTexture = r.LoadTexture(droppedFiles.paths[0]);
                    curImage = r.LoadImage(droppedFiles.paths[0]);
                }
                r.UnloadDroppedFiles(droppedFiles);
            }
            r.GuiSetStyle(r.DEFAULT, r.TEXT_SIZE, 50);
            _ = r.GuiLabel(.{ .x = 0, .y = (i.tof(window_h) / 2) - 25, .height = 50, .width = i.tof(window_w) }, "Raahaa tiedosto ikkunaan...");
            r.GuiSetStyle(r.DEFAULT, r.TEXT_SIZE, 25);
        }
    }

    if (curTexture != null) {
        r.UnloadTexture(curTexture.?);
    }

    if (curImage != null) {
        r.UnloadImage(curImage.?);
    }

    defer r.CloseWindow(); // Close window and OpenGL context
}
