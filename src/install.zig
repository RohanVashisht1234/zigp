const std = @import("std");

pub fn install_package(x: []const u8) void {
    std.debug.print("Installing {s}.\n", .{x});
    std.debug.print("Please select the version you want to install:\n", .{});
}
