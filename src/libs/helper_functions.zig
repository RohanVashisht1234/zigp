const std = @import("std");
const ansi = @import("./ansi_codes.zig");
const types = @import("../types.zig");

const MAX_ALLOWED_REPO_NAME_LENGTH = 2000;
const url = "https://api.github.com/repos/{s}/releases";
const tar_file_url = "https://github.com/{s}/archive/refs/tags/{s}.tar.gz";

pub fn fetch_versions(repo: types.repository, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    // I am doing -2 for making sure {} is not included.
    if (url.len + repo.repo_full_name.len - 2 > MAX_ALLOWED_REPO_NAME_LENGTH) {
        @panic("The length of repo name is way too much long.");
    }

    var buf: [MAX_ALLOWED_REPO_NAME_LENGTH]u8 = undefined;
    const fetch_url = try std.fmt.bufPrintZ(&buf, url, .{repo.repo_full_name});

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
            std.debug.print("{s}Error: {s}\"{s}\"{s} is not a repo.\n", .{ ansi.RED ++ ansi.BOLD, ansi.BRIGHT_CYAN, repo.repo_full_name, ansi.RESET });
            return error.invalid_responce;
        },
        else => {
            std.debug.print("{s}Didn't recieve a responce, please check your internet connection.{s}", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
            return error.invalid_responce;
        },
    }

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

pub fn query_to_repo(query: []const u8) anyerror!types.repository {
    var iterator = std.mem.splitScalar(u8, query, '/');
    const provider = iterator.next() orelse return error.wrong_format;
    const repo_full_name = iterator.rest();
    const owner = iterator.next() orelse return error.wrong_format;
    const repo_name = iterator.next() orelse return error.wrong_format;
    const unnesecary_next = iterator.next();
    if (unnesecary_next) |_| {
        return error.wrong_format;
    }

    if (std.mem.eql(u8, provider, "gh")) {
        return .{ .owner = owner, .provider = .GitHub, .repo_full_name = repo_full_name, .repo_name = repo_name };
    } else if (std.mem.eql(u8, provider, "cb")) {
        return .{ .owner = owner, .provider = .CodeBerg, .repo_full_name = repo_full_name, .repo_name = repo_name };
    } else if (std.mem.eql(u8, provider, "gl")) {
        return .{ .owner = owner, .provider = .GitLab, .repo_full_name = repo_full_name, .repo_name = repo_name };
    } else {
        return error.unknown_provider;
    }
}

pub fn fetch_info_from_github(repo: types.repository, allocator: std.mem.Allocator) !struct { license: []const u8, description: []const u8, topics: std.ArrayList([]const u8) } {
    switch (repo.provider) {
        .GitHub => {},
        else => {
            @panic("Other providers are comming soon");
        },
    }

    var buf: [2000]u8 = undefined;

    const fetch_url = try std.fmt.bufPrintZ(&buf, "https://api.github.com/repos/{s}", .{repo.repo_full_name});

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
            std.debug.print("{s}Error: {s}\"{s}\"{s} is not a repo.\n", .{ ansi.RED ++ ansi.BOLD, ansi.BRIGHT_CYAN, repo.repo_full_name, ansi.RESET });
            return error.invalid_responce;
        },
        else => {
            std.debug.print("{s}Didn't recieve a responce, please check your internet connection.{s}", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
            return error.invalid_responce;
        },
    }

    const body = response.written();

    if (body.len == 0 or body[0] != '{') {
        std.debug.print("{s}A non json responce was recieved which is most likely an error, responce recieved:\n{s}", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
        std.debug.print("{s}\n", .{body});
        return error.invalid_responce;
    }

    var json_parsed: std.json.Parsed(std.json.Value) = try std.json.parseFromSlice(std.json.Value, allocator, body, .{});
    defer json_parsed.deinit();
    const license = json_parsed.value.object.get("license").?.object.get("key").?.string;
    const description = if (json_parsed.value.object.get("description").? == .null)
        "No Description"
    else
        json_parsed.value.object.get("description").?.string;

    const topics = json_parsed.value.object.get("topics").?.array;

    var array_list: std.ArrayList([]const u8) = .empty;

    for (topics.items) |topic| {
        try array_list.append(allocator, try allocator.dupe(u8, topic.string));
    }

    return .{
        .license = try allocator.dupe(u8, license),
        .description = try allocator.dupe(u8, description),
        .topics = array_list,
    };
}
