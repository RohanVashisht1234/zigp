const std = @import("std");
const MAX_ALLOWED_REPO_NAME_LENGTH = 2000;
const url = "https://api.github.com/repos/{s}/releases";
const ansi = @import("./libs/ansi_codes.zig");

pub fn fetch_versions(repo: []const u8) !std.ArrayList([]const u8) {
    // I am doing -2 for making sure {} is not included.
    if (url.len + repo.len - 2 > MAX_ALLOWED_REPO_NAME_LENGTH) {
        @panic("The length of repo name is way too much long.");
    }
    var buf: [MAX_ALLOWED_REPO_NAME_LENGTH]u8 = undefined;
    const fetch_url = try std.fmt.bufPrintZ(&buf, url, .{repo});

    var client = std.http.Client{ .allocator = std.heap.c_allocator };
    defer client.deinit();
    var response = std.Io.Writer.Allocating.init(std.heap.c_allocator);
    defer response.deinit();
    const result = try client.fetch(.{ .location = .{ .url = fetch_url }, .response_writer = &response.writer });
    if (result.status == .not_found) {
        std.debug.print("{s}Error: {s}{s}{s} is not a repo.\n", .{ ansi.RED ++ ansi.BOLD, ansi.BRIGHT_CYAN, repo, ansi.RESET });
        std.process.exit(0);
    }
    if (result.status != .ok) {
        std.debug.print("{s}Didn't recieve a responce, please check your internet connection.{s}", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
    }
    std.debug.print("{s}Installing {s}{s}.{s}\n", .{ ansi.YELLOW, ansi.UNDERLINE, repo, ansi.RESET });
    std.debug.print("{s}Please select the version you want to install (type the index number):{s}\n", .{ ansi.BRIGHT_CYAN ++ ansi.BOLD, ansi.RESET });
    const body = response.written();
    if (body.len == 0 or body[0] != '[') {
        std.debug.print("{s}A non json responce was recieved which is most likely an error, responce recieved:\n{s}", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
        std.debug.print("{s}\n", .{body});
        std.process.exit(0);
    }

    const j: std.json.Parsed(std.json.Value) = try std.json.parseFromSlice(std.json.Value, std.heap.c_allocator, body, .{});
    var list: std.ArrayList([]const u8) = .empty;
    try list.append(std.heap.c_allocator, "Master Branch (unstable)");
    const all_releases = j.value.array.items;
    if (all_releases.len != 0) {
        for (all_releases) |single_release| {
            try list.append(std.heap.c_allocator, single_release.object.get("tag_name").?.string);
        }
        return list;
    }
    unreachable;
}

// https://github.com/RohanVashisht1234/zorsig/archive/refs/tags/v0.0.1.tar.gz
// https://github.com/{}/archive/refs/tags/{}.tar.gz

pub fn install_package(repo_name: []const u8) !void {
    const d = try fetch_versions(repo_name);
    // const x = "https://github.com/{}/archive/refs/tags/{}.tar.gz";
    for (d.items, 1..) |value, i| {
        std.debug.print("{}){s} {s}{s}\n", .{ i, ansi.BOLD, value, ansi.RESET });
    }

    const stdin = std.fs.File.stdin();

    outer: while (true) {
        std.debug.print(">>>", .{});
        var buf: [16]u8 = undefined;
        const len = try stdin.read(&buf);
        var input = buf[0..len];
        if (input.len > 0 and (input[input.len - 1] == '\n' or input[input.len - 1] == '\r')) {
            input = input[0 .. input.len - 1];
        }
        if (input.len == 0) {
            std.debug.print("{s}Error:{s} No input entered.\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
            continue :outer;
        }
        for (input) |char| {
            if (!std.ascii.isDigit(char)) {
                std.debug.print("{s}Error:{s} Non charater input recieved.\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
                continue :outer;
            }
        }
        const number = try std.fmt.parseInt(u16, input, 10);
        if (number < 1 or number > d.items.len) {
            std.debug.print("{s}Error:{s} Number selection is out of range.\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
            continue :outer;
        }
        const items = d.items;
        std.debug.print("{s}Installing: {s}\n", .{items[number - 1]});
        break;
    }
}
