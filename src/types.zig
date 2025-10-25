pub const repository = struct {
    provider: enum { GitHub, CodeBerg, GitLab },
    owner: []const u8,
    name: []const u8,
    full_name: []const u8,
};
