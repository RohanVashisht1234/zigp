const std = @import("std");
const display = @import("display.zig");
const install = @import("add_package.zig");

inline fn eql(x: []const u8, y: []const u8) bool {
    return std.mem.eql(u8, x, y);
}

fn self_update(allocator: std.mem.Allocator) !void {
    var process = std.process.Child.init(&[_][]const u8{ "curl", "-fsSL", "https://zigistry.dev/update", "|", "bash" }, allocator);
    process.stdout_behavior = .Inherit;

    const result = try process.spawnAndWait();
    switch (result.Exited) {
        0 => display.success.completed_self_update(),
        1 => display.err.failed_self_update(),
        else => display.err.unexpected_failed_self_update(result.Exited),
    }
}

pub fn main() !void {
    // allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory got leaked.");
    }

    // arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // parse
    switch (args.len) {

        // zigp
        1 => display.help.all_info(),

        // args[0]  args[1]
        // zigp     something
        2 => if (eql(args[1], "add")) {
            display.help.add_info();
        } else if (eql(args[1], "install")) {
            display.help.install_info();
        } else if (eql(args[1], "help")) {
            display.help.all_info();
        } else if (eql(args[1], "self-update")) {
            try self_update(allocator);
        } else if (eql(args[1], "version")) {
            std.debug.print("v0.0.0", .{});
        } else display.err.unknown_argument(args[1]),

        // args[0]  args[1]     args[2]
        // zigp     something   something_else
        3 => {
            if (eql(args[1], "install")) {
                var split_iter = std.mem.splitScalar(u8, args[2], '/');
                const provider = split_iter.next().?;
                if (!eql(provider, "gh")) {
                    // I will soon implement other providers.
                    display.err.unknown_provider(provider);
                    return;
                }
                const repo_name = split_iter.rest();
                try install.install_app(repo_name);
            } else if (eql(args[1], "add")) {
                var split_iter = std.mem.splitScalar(u8, args[2], '/');
                const provider = split_iter.next().?;
                if (!eql(provider, "gh")) {
                    display.err.unknown_provider(provider);
                    return;
                }
                const repo_name = split_iter.rest();
                try install.add_package(repo_name);
            } else display.err.unknown_argument(args[2]);
        },

        // args[0]  args[1]     args[2]         args[3]
        // zigp     something   something_else  yet_something
        else => display.err.unknown_argument(args[2]),
    }
}
