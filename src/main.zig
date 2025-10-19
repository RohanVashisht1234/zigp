const std = @import("std");
const allocator = std.heap.c_allocator;
const display = @import("display.zig");
const install = @import("install.zig");

fn self_update() !void {
    var process = std.process.Child.init(&[_][]const u8{ "curl", "-fsSL", "https://zigistry.dev/update", "|", "bash" }, allocator);
    process.stdout_behavior = .Inherit;

    try process.spawn();

    const result = try process.wait();
    switch (result.Exited) {
        0 => display.success.completed_self_update(),
        1 => display.err.failed_self_update(),
        else => display.err.unexpected_failed_self_update(result.Exited),
    }
}
// ./zig-out/bin/foo install provider/something/something
pub fn main() !void {
    const x = try std.process.argsAlloc(allocator);
    if (x.len == 1) {
        display.help.all_info();
    } else if (x.len == 2) {
        if (std.mem.eql(u8, x[1], "install")) {
            display.help.install_info();
        } else if (std.mem.eql(u8, x[1], "help") or std.mem.eql(u8, x[1], "--help")) {
            display.help.all_info();
        } else if (std.mem.eql(u8, x[1], "self-update")) {
            try self_update();
        } else if (std.mem.eql(u8, x[1], "version")) {
            std.debug.print("v0.0.0", .{});
        } else {
            display.err.unknown_argument(x[1]);
        }
    } else if (x.len == 3 and std.mem.eql(u8, x[1], "install")) {
        // for now, i only have github provider, i'll soon add more providers.
        var split_iter = std.mem.splitScalar(u8, x[2], '/');
        const provider = split_iter.next().?;
        if (!std.mem.eql(u8, provider, "gh")) {
            display.err.unknown_provider(provider);
            return;
        }
        const repo_name = split_iter.rest();
        try install.install_package(repo_name);
    } else {
        display.err.unknown_argument(x[2]);
    }
}
