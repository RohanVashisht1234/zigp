const std = @import("std");
const MAX_ALLOWED_REPO_NAME_LENGTH = 2000;
const url = "https://api.github.com/repos/{s}/releases";

pub fn fetch_versions(repo: []const u8) !std.StringArrayHashMap([]const u8) {
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
    if (result.status != .ok) @panic("oh no");
    const body = response.written();

    const j: std.json.Parsed(std.json.Value) = try std.json.parseFromSlice(std.json.Value, std.heap.c_allocator, body, .{});
    var hashmap = std.StringArrayHashMap([]const u8).init(std.heap.page_allocator);
    const all_releases = j.value.array.items;
    if (all_releases.len != 0) {
        for (all_releases) |single_release| {
            try hashmap.put(single_release.object.get("tag_name").?.string, single_release.object.get("tarball_url").?.string);
        }
        return hashmap;
    }
    unreachable;
}

pub fn install_package(x: []const u8) !void {
    std.debug.print("Installing {s}.\n", .{x});
    std.debug.print("Please select the version you want to install:\n", .{});
    const d = try fetch_versions(x);
    var iter = d.iterator();
    while (iter.next()) |next_value| {
        std.debug.print("{s}:{s}\n", .{next_value.key_ptr.*, next_value.value_ptr.*});
    }
}
