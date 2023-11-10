const r = @import("ray.zig").r;

pub const SIDEBAR_SIZE = 400;

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
