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
        var fullPath = try std.fmt.allocPrint(allocator, "{s}{s}", .{ "./uudet/", entry.path });
        imgList.append(r.LoadImage(@as([*c]const u8, @ptrCast(fullPath)))) catch unreachable;
        texList.append(r.LoadTexture(@as([*c]const u8, @ptrCast(fullPath)))) catch unreachable;
        walkcount += 1;
        allocator.free(fullPath);
    }

    var doExport = false;

    while (!r.WindowShouldClose()) {
        var texture = texList.items[0];
        if (doExport) {
            exporter.exportImages(imgList.items[0], rectList, texture, screen_width, screen_height, allocator);
            doExport = false;
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
        i.drawTexLetterboxed(texture, screen_width, screen_height);
        if (rectStart != null) {
            var mouseP = r.GetMousePosition();
            var mouseDiff = r.Vector2Subtract(mouseP, rectStart.?);
            r.DrawRectangle(i.toi(rectStart.?.x), i.toi(rectStart.?.y), i.toi(mouseDiff.x), i.toi(mouseDiff.y), r.RED);
        }

        for (rectList.items) |rect| {
            r.DrawRectangle(i.toi(rect.x), i.toi(rect.y), i.toi(rect.width), i.toi(rect.height), r.BLUE);
        }
    }

    // Free
    for (texList.items) |tex| {
        r.UnloadTexture(tex);
    }
    for (imgList.items) |img| {
        r.UnloadImage(img);
    }

    defer r.CloseWindow(); // Close window and OpenGL context
}
