const std = @import("std");

pub const help = struct {
    pub fn all_info() void {
        const help_message =
            \\Welcome to Zigistry-cli!
            \\ 
            \\ 
            \\Here are some commands we have
            \\------------------------------------------------
            \\install - This is used to install a Zig package.
            \\Example Usage:
            \\        zigp install capy-ui/capy
            \\------------------------------------------------
            \\version - Displays the version of zigp.
            \\------------------------------------------------
            \\self-update - Zigp will update itself.
            \\------------------------------------------------
            \\
            \\♥ Made with Love by https://zigistry.dev ♥
            \\
        ;
        std.debug.print(help_message, .{});
    }
    pub fn install_info() void {
        const help_message =
            \\The install command is used to install a package into a zig project.
            \\
            \\Syntax:
            \\         zigp install <package-name>
            \\Example usage:
            \\         zigp install capy-ui/capy
            \\
        ;
        std.debug.print(help_message, .{});
    }
};

pub const err = struct {
    pub fn unknown_argument(x: []const u8) void {
        std.debug.print("Unknown argument recieved: {s}\n", .{x});
    }
    pub fn failed_self_update() void {
        std.debug.print("Zigp wasn't able to update itself. Some error occured in the build script.\n", .{});
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
