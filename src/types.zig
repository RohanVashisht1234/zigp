pub const repository = struct {
    provider: enum { GitHub, CodeBerg, GitLab },
    owner: []const u8,
    repo_name: []const u8,
    repo_full_name: []const u8,
};
