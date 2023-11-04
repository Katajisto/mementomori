const std = @import("std");

pub fn printIntro() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n\n--------------------------\nMemento mori luo Anki-kortteja. Siirrä kuvat joista haluat tehdä kortteja uudet/ kansioon.\n", .{});
    try stdout.print("Uusi korttipakka luodaan pakat/ kansioon. Kuvat joista tämä pakka tehtiin, siirretään vanhat/ kansioon.\n", .{});
    try stdout.print("Jos haluat lisätä kortteja jo olemassaolevaan pakkaan, anna nimeä kysyttäessä vastaukseksi jo olemassaolevan pakan nimi.\n", .{});
    try stdout.print("Tuomas Katajisto - 2023\n--------------------------\n\n", .{});
}
