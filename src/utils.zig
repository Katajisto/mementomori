const std = @import("std");

pub const conf = struct {
    ankiMedia: std.ArrayList(u8),
    exportLoc: std.ArrayList(u8),

    pub fn deinit(self: *conf) void {
        self.ankiMedia.deinit();
        self.exportLoc.deinit();
    }
};

pub fn readConf(allocator: std.mem.Allocator) !conf {
    var file = try std.fs.cwd().openFile("conf", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var linenum: i32 = 0;
    var ankiMediaStr = std.ArrayList(u8).init(allocator);
    var ankiExportStr = std.ArrayList(u8).init(allocator);
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (linenum == 0) {
            ankiMediaStr.appendSlice(line) catch unreachable;
        }
        if (linenum == 1) {
            ankiExportStr.appendSlice(line) catch unreachable;
        }
        if (linenum > 1) {
            break;
        }
        linenum += 1;
    }

    return conf{ .ankiMedia = ankiMediaStr, .exportLoc = ankiExportStr };
}
