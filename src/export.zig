const r = @import("ray.zig").r;
const std = @import("std");

pub fn exportImages(img: r.Image, rectList: std.ArrayList(r.Rectangle)) void {
    _ = img;
    for (0..rectList.items.len) |i| {
        _ = i;
    }
}
