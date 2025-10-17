const std = @import("std");
const allocator = std.heap.c_allocator;
const display = @import("display.zig");
const install = @import("install.zig");

fn self_update() !void {
    var process = std.process.Child.init(&[_][]const u8{ "curl", "" }, allocator);
    process.stdout_behavior = .Inherit;

    try process.spawn();

    const result = try process.wait();
    switch (result.Exited) {
        0 => display.success.completed_self_update(),
        1 => display.err.failed_self_update(),
        else => display.err.unexpected_failed_self_update(result.Exited),
    }
}
// ./zig-out/bin/foo install something
pub fn main() !void {
    const x = try std.process.argsAlloc(allocator);
    if (x.len == 1) {
        display.help.all_info();
    } else if (x.len == 2) {
        if (std.mem.eql(u8, x[1], "install")) {
            display.help.install_info();
        } else if (std.mem.eql(u8, x[1], "help") or std.mem.eql(u8, x[1], "--help")) {
            display.help.all_info();
        } else if (std.mem.eql(u8, x[1], "selfupdate")) {
            try self_update();
        } else if (std.mem.eql(u8, x[1], "version")) {
            std.debug.print("v0.0.0", .{});
        } else {
            display.err.unknown_argument(x[1]);
        }
    } else if (x.len == 3 and std.mem.eql(u8, x[1], "install")) {
        try install.install_package(x[2]);
    } else {
        display.err.unknown_argument(x[2]);
    }
}
