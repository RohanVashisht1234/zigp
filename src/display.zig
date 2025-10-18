const std = @import("std");
const ansi = @import("./libs/ansi_codes.zig");

pub const help = struct {
    pub fn all_info() void {
        std.debug.print("{s}╔══════════════════════════════════════════════════════╗{s}\n", .{ ansi.BRIGHT_CYAN, ansi.RESET });
        std.debug.print("{s}║               Welcome to Zigistry-CLI!               ║{s}\n", .{ ansi.BRIGHT_CYAN, ansi.RESET });
        std.debug.print("{s}╚══════════════════════════════════════════════════════╝{s}\n\n", .{ ansi.BRIGHT_CYAN, ansi.RESET });

        std.debug.print("{s}Here are some commands you can use:{s}\n", .{ ansi.BRIGHT_YELLOW, ansi.RESET });
        std.debug.print("{s}--------------------------------------------------------{s}\n", .{ ansi.BRIGHT_WHITE, ansi.RESET });

        std.debug.print("{s}install{s}      - Install a Zig package.\n", .{ ansi.BRIGHT_GREEN, ansi.RESET });
        std.debug.print("    Example: {s}zigp{s} install {s}capy-ui/capy{s}\n", .{ ansi.BRIGHT_MAGENTA, ansi.BRIGHT_WHITE, ansi.BRIGHT_MAGENTA, ansi.RESET });
        std.debug.print("{s}--------------------------------------------------------{s}\n", .{ ansi.BRIGHT_WHITE, ansi.RESET });

        std.debug.print("{s}version{s}      - Display the version of zigp.\n", .{ ansi.BRIGHT_GREEN, ansi.RESET });
        std.debug.print("{s}--------------------------------------------------------{s}\n", .{ ansi.BRIGHT_WHITE, ansi.RESET });

        std.debug.print("{s}self-update{s}  - Update zigp itself to the latest version.\n", .{ ansi.BRIGHT_GREEN, ansi.RESET });
        std.debug.print("{s}--------------------------------------------------------{s}\n\n", .{ ansi.BRIGHT_WHITE, ansi.RESET });

        std.debug.print("{s}♥{s} Made with {s}Love{s} by {s}https://zigistry.dev{s} {s}♥{s}\n\n", .{ ansi.BRIGHT_MAGENTA, ansi.RESET, ansi.BRIGHT_YELLOW, ansi.RESET, ansi.BRIGHT_CYAN, ansi.RESET, ansi.BRIGHT_MAGENTA, ansi.RESET });
    }

    pub fn install_info() void {
        std.debug.print("{s}╔══════════════════════════════════════════════╗\n", .{
            ansi.BRIGHT_CYAN,
        });
        std.debug.print("║            Zigistry Install Command          ║\n", .{});
        std.debug.print("╚══════════════════════════════════════════════╝{s}\n\n", .{ansi.RESET});

        std.debug.print("{s}Description:{s}\n", .{ ansi.BRIGHT_YELLOW, ansi.RESET });
        std.debug.print("    The install command is used to add a package into your Zig project.\n\n", .{});

        std.debug.print("{s}Syntax:{s}\n", .{ ansi.BRIGHT_YELLOW, ansi.RESET });
        std.debug.print("    {s}zigp{s} install {s}<package-name>{s}\n\n", .{ ansi.BRIGHT_MAGENTA, ansi.BRIGHT_GREEN, ansi.BRIGHT_MAGENTA, ansi.RESET });

        std.debug.print("{s}Example:{s}\n", .{ ansi.BRIGHT_YELLOW, ansi.RESET });
        std.debug.print("    {s}zigp{s} install {s}capy-ui/capy{s}\n\n", .{ ansi.BRIGHT_MAGENTA, ansi.BRIGHT_GREEN, ansi.BRIGHT_MAGENTA, ansi.RESET });
    }
};

pub const err = struct {
    pub fn unknown_argument(x: []const u8) void {
        std.debug.print("{s}{s}Unknown argument recieved: {s}{s}\n", .{ ansi.RED, ansi.BOLD, x, ansi.RESET });
    }
    pub fn failed_self_update() void {
        std.debug.print("{s}{s}Zigp wasn't able to update itself. Some error occured in the build script.{s}\n", .{ ansi.RED, ansi.BOLD, ansi.RESET });
    }
    pub fn unexpected_failed_self_update(x: u8) void {
        std.debug.print("Zigp wasn't able to update itself due to an unknown or unexpected issue. Value returned: {}\n", .{x});
    }
};

pub const success = struct {
    pub fn completed_self_update() void {
        std.debug.print("Success fully updated itself\n", .{});
    }
};
