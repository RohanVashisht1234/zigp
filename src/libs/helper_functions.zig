const std = @import("std");
const ansi = @import("./ansi_codes.zig");

const MAX_ALLOWED_REPO_NAME_LENGTH = 2000;
const url = "https://api.github.com/repos/{s}/releases";
const tar_file_url = "https://github.com/{s}/archive/refs/tags/{s}.tar.gz";

pub fn fetch_versions(repo: []const u8, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    // I am doing -2 for making sure {} is not included.
    if (url.len + repo.len - 2 > MAX_ALLOWED_REPO_NAME_LENGTH) {
        @panic("The length of repo name is way too much long.");
    }

    var buf: [MAX_ALLOWED_REPO_NAME_LENGTH]u8 = undefined;
    const fetch_url = try std.fmt.bufPrintZ(&buf, url, .{repo});

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var response = std.Io.Writer.Allocating.init(allocator);
    defer response.deinit();

    const result = try client.fetch(.{
        .location = .{ .url = fetch_url },
        .response_writer = &response.writer,
    });

    switch (result.status) {
        .ok => {},
        .not_found => {
            std.debug.print("{s}Error: {s}{s}{s} is not a repo.\n", .{ ansi.RED ++ ansi.BOLD, ansi.BRIGHT_CYAN, repo, ansi.RESET });
            return error.invalid_responce;
        },
        else => {
            std.debug.print("{s}Didn't recieve a responce, please check your internet connection.{s}", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
            return error.invalid_responce;
        },
    }

    std.debug.print("{s}Installing {s}{s}{s}\n", .{ ansi.YELLOW, ansi.UNDERLINE, repo, ansi.RESET });
    std.debug.print("{s}Please select the version you want to install (type the index number):{s}\n", .{ ansi.BRIGHT_CYAN ++ ansi.BOLD, ansi.RESET });

    const body = response.written();

    if (body.len == 0 or body[0] != '[') {
        std.debug.print("{s}A non json responce was recieved which is most likely an error, responce recieved:\n{s}", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
        std.debug.print("{s}\n", .{body});
        return error.invalid_responce;
    }

    const json_handler: std.json.Parsed(std.json.Value) = try std.json.parseFromSlice(std.json.Value, allocator, body, .{});
    defer json_handler.deinit();

    var list: std.ArrayList([]const u8) = .empty;

    try list.append(allocator, try allocator.dupe(u8, "Master Branch (unstable)"));

    const all_releases = json_handler.value.array.items;

    if (all_releases.len != 0) {
        for (all_releases) |single_release| {
            const tag = single_release.object.get("tag_name").?.string;
            const duplicated_tag_string = try allocator.dupe(u8, tag);
            try list.append(allocator, duplicated_tag_string);
        }
    }

    return list;
}
