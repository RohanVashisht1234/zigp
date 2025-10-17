const std = @import("std");
const MAX_ALLOWED_REPO_NAME_LENGTH = 2000;
const url = "https://api.github.com/repos/";

pub fn fetch_versions(repo: []const u8) std.StringArrayHashMap([]const u8) {
    if (url.len + repo.len > MAX_ALLOWED_REPO_NAME_LENGTH) {
        @panic("The length of repo name is way too much long.");
    }
    const Client = std.http.Client;
    const FetchOptions = Client.FetchOptions;
    const Uri = std.Uri;
    var client = Client{ .allocator = std.heap.c_allocator };
    defer client.deinit();
    var buf: [MAX_ALLOWED_REPO_NAME_LENGTH]u8 = undefined;
    const resa = try std.fmt.bufPrintZ(&buf, "https://api.github.com/repos/{}/releases", .{repo});
    const uri = try Uri.parse(resa);

    const writer: std.ArrayList(u8) = .empty;
    const opts: FetchOptions = .{
        .method = .GET,
        .location = .{ .uri = uri },
        .response_writer = writer.writer(std.heap.c_allocator),
    };
    const response = try client.fetch(opts);
    if (response.status == .ok) {
        const res = writer.items;
        std.debug.print("{s}", .{res});
        const j:std.json.Value = try std.json.parseFromSlice(std.json.Value, std.heap.c_allocator, res, .{});
        const hashmap = std.StringArrayHashMap([]const u8).init(std.heap.page_allocator);
        const all_releases = j.array.items;
        if(all_releases.len == 0) {
            
        }
    } else {
        @panic("Request failed, check your internet please!");
    }
    unreachable;
}
