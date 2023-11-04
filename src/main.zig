const r = @import("ray.zig").r;
const utils = @import("utils.zig");
const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var screen_width: i32 = 700;
    var screen_height: i32 = 700;
    r.SetTraceLogLevel(r.LOG_ERROR);
    r.InitWindow(screen_width, screen_height, "Memento mori");

    try utils.printIntro();

    var cwd = fs.cwd();
    var uudet = try cwd.openIterableDir("uudet", .{});

    var walker = try uudet.walk(allocator);
    defer walker.deinit();

    var list = std.ArrayList(r.Texture2D).init(allocator);
    defer list.deinit();

    var walkcount: usize = 0;
    while (try walker.next()) |entry| {
        if (walkcount > 99) {
            continue;
        }
        list.append(r.LoadTexture(entry.basename));
        walkcount += 1;
    }

    defer r.CloseWindow(); // Close window and OpenGL context
}
