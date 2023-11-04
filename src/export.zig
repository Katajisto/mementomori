const r = @import("ray.zig").r;
const img = @import("image.zig");
const std = @import("std");

pub fn tof(x: i32) f32 {
    return @as(f32, @floatFromInt(x));
}

pub fn toi(x: f32) i32 {
    return @as(i32, @intFromFloat(x));
}

pub fn exportImages(image: r.Image, rectList: std.ArrayList(r.Rectangle), tex: r.Texture2D, sw: i32, sh: i32, alloc: std.mem.Allocator) void {
    var ankicontent = std.ArrayList(u8).init(alloc);
    defer ankicontent.deinit();

    for (0..rectList.items.len) |i| {
        var imgCpy = r.ImageCopy(image);
        var imgCpySolution = r.ImageCopy(image);
        for (0..rectList.items.len) |j| {
            if (i == j) {
                var curRect = rectList.items[j];
                var curRectCorrectedStart = img.transformScreenCoordsToImageSpace(.{ .x = curRect.x, .y = curRect.y }, img.calcImgSize(tex, sw, sh), tex);
                var curRectCorrectedEnd = img.transformScreenCoordsToImageSpace(.{ .x = curRect.x + curRect.width, .y = curRect.y + curRect.height }, img.calcImgSize(tex, sw, sh), tex);
                var correctedSize = r.Vector2Subtract(curRectCorrectedEnd, curRectCorrectedStart);
                r.ImageDrawRectangle(&imgCpy, toi(curRectCorrectedStart.x), toi(curRectCorrectedStart.y), toi(correctedSize.x), toi(correctedSize.y), r.RED);
            } else {
                var curRect = rectList.items[j];
                var curRectCorrectedStart = img.transformScreenCoordsToImageSpace(.{ .x = curRect.x, .y = curRect.y }, img.calcImgSize(tex, sw, sh), tex);
                var curRectCorrectedEnd = img.transformScreenCoordsToImageSpace(.{ .x = curRect.x + curRect.width, .y = curRect.y + curRect.height }, img.calcImgSize(tex, sw, sh), tex);
                var correctedSize = r.Vector2Subtract(curRectCorrectedEnd, curRectCorrectedStart);
                r.ImageDrawRectangle(&imgCpy, toi(curRectCorrectedStart.x), toi(curRectCorrectedStart.y), toi(correctedSize.x), toi(correctedSize.y), r.BLUE);
                r.ImageDrawRectangle(&imgCpySolution, toi(curRectCorrectedStart.x), toi(curRectCorrectedStart.y), toi(correctedSize.x), toi(correctedSize.y), r.BLUE);
            }
        }
        var fullPath = std.fmt.allocPrint(alloc, "{s}{d}-{d}.png", .{ "./pakat/x/collection.media/", 123, i }) catch unreachable;
        var fullPathSol = std.fmt.allocPrint(alloc, "{s}{d}-{d}-sol.png", .{ "./pakat/x/collection.media/", 123, i }) catch unreachable;
        var path = std.fmt.allocPrint(alloc, "{d}-{d}.png", .{ 123, i }) catch unreachable;
        var pathSol = std.fmt.allocPrint(alloc, "{d}-{d}-sol.png", .{ 123, i }) catch unreachable;
        _ = r.ExportImage(imgCpy, @as([*c]const u8, @ptrCast(fullPath)));
        _ = r.ExportImage(imgCpySolution, @as([*c]const u8, @ptrCast(fullPathSol)));
        var ankiline = std.fmt.allocPrint(alloc, "<img src=\"{s}\">;<img src=\"{s}\">\n", .{ path, pathSol }) catch unreachable;
        _ = ankicontent.appendSlice(ankiline) catch unreachable;
        alloc.free(fullPath);
        alloc.free(fullPathSol);
        alloc.free(path);
        alloc.free(pathSol);
        alloc.free(ankiline);
    }

    var ankifile = std.fs.cwd().createFile("./pakat/x/collection.txt", .{ .read = true }) catch unreachable;
    _ = ankifile.write(ankicontent.items) catch unreachable;
    ankifile.close();
}