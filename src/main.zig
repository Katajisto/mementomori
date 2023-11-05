const r = @import("ray.zig").r;
const i = @import("image.zig");
const utils = @import("utils.zig");
const exporter = @import("export.zig");
const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var screen_width: i32 = 1920;
    var screen_height: i32 = 1080;
    // r.SetTraceLogLevel(r.LOG_ERROR);
    // r.SetConfigFlags(r.FLAG_WINDOW_RESIZABLE);
    r.InitWindow(screen_width, screen_height, "Jennin Anki työkalu v0.5");

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

    var filename = [_]u8{0} ** 100;

    while (!r.WindowShouldClose()) {
        if (doExport and exportScreenFrames > 2) {
            exporter.exportImages(curImage.?, rectList, curTexture.?, screen_width, screen_height, allocator, conf, @as([*:0]u8, @ptrCast(&filename)));
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
                if ((mouseDiff.x > 0 and mouseDiff.y > 0) or (mouseDiff.x < 0 and mouseDiff.y < 0)) {
                    rectList.append(.{ .x = rectStart.?.x, .y = rectStart.?.y, .width = mouseDiff.x, .height = mouseDiff.y }) catch unreachable;
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
            i.drawTexLetterboxed(curTexture.?, screen_width, screen_height);
            if (rectStart != null) {
                var mouseP = r.GetMousePosition();
                var mouseDiff = r.Vector2Subtract(mouseP, rectStart.?);
                r.DrawRectangle(i.toi(rectStart.?.x), i.toi(rectStart.?.y), i.toi(mouseDiff.x), i.toi(mouseDiff.y), r.RED);
            }

            for (rectList.items) |rect| {
                r.DrawRectangle(i.toi(rect.x), i.toi(rect.y), i.toi(rect.width), i.toi(rect.height), r.BLUE);
            }
            r.DrawRectangle(0, 0, 400, 1080, r.Color{ .r = 190, .g = 190, .b = 190, .a = 255 });
            _ = r.GuiLabel(.{ .x = 10, .y = 10, .width = 380, .height = 40 }, "Jennin Anki työkalu");
            if (r.GuiButton(.{ .x = 10, .y = 1000, .width = 380, .height = 40 }, "Vie pakka") == 1 and filename[0] != 0) {
                doExport = true;
            }
            if (r.GuiButton(.{ .x = 10, .y = 950, .width = 380, .height = 40 }, "Poista viimeinen suorakulmio") == 1) {
                if (rectList.items.len > 0) {
                    _ = rectList.orderedRemove(rectList.items.len - 1);
                }
            }

            _ = r.GuiLabel(.{ .x = 10, .y = 120, .height = 30, .width = 380 }, "Tiedostonimi");
            r.GuiSetStyle(r.DEFAULT, r.TEXT_ALIGNMENT, r.TEXT_ALIGN_LEFT);
            _ = r.GuiTextBox(.{ .x = 10, .y = 170, .width = 380, .height = 40 }, @as([*c]u8, @ptrCast(&filename)), 30, true);
            r.GuiSetStyle(r.DEFAULT, r.TEXT_ALIGNMENT, r.TEXT_ALIGN_CENTER);
            _ = r.GuiLabel(.{ .x = 10, .y = 1050, .height = 30, .width = 380 }, "Katajisto 2023");
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
            _ = r.GuiLabel(.{ .x = 0, .y = 400, .height = 50, .width = 1920 }, "Raahaa tiedosto ikkunaan...");
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
