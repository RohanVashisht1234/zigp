const std = @import("std");

pub const repository = struct {
    provider: enum { GitHub, CodeBerg, GitLab },
    owner: []const u8,
    name: []const u8,
    full_name: []const u8,
};

pub const zigp_zon = struct {
    zigp_version: []const u8,
    zig_version: []const u8,
    last_updated: []const u8,
    dependencies: std.StringArrayHashMapUnmanaged(Dependency) = .empty,
    pub const Dependency = struct {
        owner_name: []const u8,
        repo_name: []const u8,
        provider: enum { GitHub, CodeBerg, GitLab },
        version: []const u8,
    };
};

pub const build_zig_zon = struct {
    name: ?[]const u8 = null,
    version: ?[]const u8 = null,
    dependencies: std.StringArrayHashMapUnmanaged(Dependency) = .empty,

    pub const Dependency = struct {
        url: ?[]const u8 = null,
        hash: ?[]const u8 = null,
        path: ?[]const u8 = null,
        lazy: ?bool = null,
    };
};
