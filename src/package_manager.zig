const std = @import("std");
const ansi = @import("./libs/ansi_codes.zig");
const hfs = @import("./libs/helper_functions.zig");
const types = @import("types.zig");

const url = "https://api.github.com/repos/{s}/releases";
const tar_file_url = "https://github.com/{s}/archive/refs/tags/{s}.tar.gz";

// https://github.com/RohanVashisht1234/zorsig/archive/refs/tags/v0.0.1.tar.gz
// https://github.com/{}/archive/refs/tags/{}.tar.gz

pub fn add_package(repo: types.repository, allocator: std.mem.Allocator) !void {
    const stdin = std.fs.File.stdin();

    var versions = hfs.fetch_versions(repo, allocator) catch return;

    const items = versions.items;

    defer {
        for (items) |item| {
            allocator.free(item);
        }
        versions.deinit(allocator);
    }

    std.debug.print("{s}Installing {s}{s}{s}\n", .{ ansi.YELLOW, ansi.UNDERLINE, repo.repo_full_name, ansi.RESET });
    std.debug.print("{s}Please select the version you want to install (type the index number):{s}\n", .{ ansi.BRIGHT_CYAN ++ ansi.BOLD, ansi.RESET });

    for (items, 1..) |value, i| {
        std.debug.print("{}){s} {s}{s}\n", .{ i, ansi.BOLD, value, ansi.RESET });
    }

    outer: while (true) {
        std.debug.print("{s}>>>{s} ", .{ ansi.BRIGHT_CYAN, ansi.RESET });

        var buf: [16]u8 = undefined;

        const len = try stdin.read(&buf);

        var input = buf[0..len];

        if (input.len == 0) {
            std.debug.print("{s}Error:{s} No input entered.\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
            continue :outer;
        }

        if (input.len > 0 and (input[input.len - 1] == '\n' or input[input.len - 1] == '\r')) {
            input = input[0 .. input.len - 1];
        }

        for (input) |char| {
            if (!std.ascii.isDigit(char)) {
                std.debug.print("{s}Error:{s} Non charater input recieved.\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
                continue :outer;
            }
        }

        const number = try std.fmt.parseInt(u16, input, 10);

        if (number < 1 or number > items.len) {
            std.debug.print("{s}Error:{s} Number selection is out of range.\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
            continue;
        }

        var buf2: [2500]u8 = undefined;

        const tag_to_install = if (number == 1)
            try std.fmt.bufPrintZ(&buf2, "git+https://github.com/{s}", .{repo.repo_full_name})
        else
            try std.fmt.bufPrintZ(&buf2, tar_file_url, .{ repo.repo_full_name, items[number - 1] });

        std.debug.print("{s}Adding package: {s}{s}{s}\n", .{ ansi.BRIGHT_YELLOW, ansi.UNDERLINE, items[number - 1], ansi.RESET });

        var process = std.process.Child.init(&[_][]const u8{ "zig", "fetch", "--save", tag_to_install }, std.heap.c_allocator);
        const term = try process.spawnAndWait();
        switch (term.Exited) {
            0 => {
                std.debug.print("{s}Successfully installed {s}.{s}\n", .{ ansi.BRIGHT_GREEN ++ ansi.BOLD, repo.repo_full_name, ansi.RESET });
                std.debug.print("{s}✧ Suggestion:{s}\n", .{ ansi.BRIGHT_MAGENTA ++ ansi.BOLD, ansi.RESET });
                std.debug.print("You can add these lines to your build.zig (just above the b.installArtifact(exe) line).\n\n", .{});
                const suggestor =
                    ansi.BRIGHT_BLUE ++ "const" ++ ansi.BRIGHT_CYAN ++ " {s} " ++ ansi.RESET ++ "= " ++ ansi.BRIGHT_CYAN ++ "b" ++ ansi.RESET ++ "." ++ ansi.BRIGHT_YELLOW ++ "dependency" ++ ansi.RESET ++ "(" ++ ansi.BRIGHT_GREEN ++ "\"{s}\"" ++ ansi.RESET ++ ", ." ++ ansi.BRIGHT_MAGENTA ++ "{{}}" ++ ansi.RESET ++ ");" ++ "\n" ++
                    ansi.BRIGHT_CYAN ++ "exe" ++ ansi.RESET ++ "." ++ ansi.BRIGHT_BLUE ++ "root_module" ++ ansi.RESET ++ "." ++ ansi.BRIGHT_YELLOW ++ "addImport" ++ ansi.RESET ++ "(" ++ ansi.BRIGHT_GREEN ++ "\"{s}\"" ++ ansi.RESET ++ "," ++ ansi.BRIGHT_CYAN ++ " {s}" ++ ansi.RESET ++ "." ++ ansi.BRIGHT_YELLOW ++ "module" ++ ansi.RESET ++ "(" ++ ansi.BRIGHT_GREEN ++ "\"{s}\"" ++ ansi.RESET ++ "));\n";
                std.debug.print(suggestor, .{ repo.repo_name, repo.repo_name, repo.repo_name, repo.repo_name, repo.repo_name });
            },
            1 => std.debug.print("{s}Zig fetch returned an error. The process returned 1 exit code.{s}\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET }),
            else => std.debug.print("{s}Zig fetch returned an unknown error. It returned {} exit code.{s}\n", .{ ansi.RED ++ ansi.BOLD, term.Exited, ansi.RESET }),
        }
        break;
    }
}

pub fn info(repo: types.repository, allocator: std.mem.Allocator) !void {
    var versions = try hfs.fetch_versions(repo, allocator);
    defer {
        const items = versions.items;
        for (items) |item| {
            allocator.free(item);
        }
        versions.deinit(allocator);
    }

    var github_info = try hfs.fetch_info_from_github(repo, allocator);
    defer {
        allocator.free(github_info.license);
        allocator.free(github_info.description);
        const items = github_info.topics.items;
        for (items) |item| {
            allocator.free(item);
        }
        github_info.topics.deinit(allocator);
    }

    const version = switch (versions.items.len) {
        1 => "latest (unstable) no releases found.",
        else => versions.items[1],
    };
    std.debug.print("{s}{s}{s}", .{ ansi.BRIGHT_GREEN ++ ansi.BOLD, repo.repo_full_name, ansi.RESET });
    for (github_info.topics.items, 1..) |topic, i| {
        if (i == 6) break;
        std.debug.print(" {s}#{s}{s}", .{ ansi.BRIGHT_CYAN ++ ansi.UNDERLINE ++ ansi.BOLD, topic, ansi.RESET });
    }
    std.debug.print("\n", .{});
    std.debug.print("{s}\n", .{github_info.description});
    std.debug.print("{s}license{s}: {s}{s}\n", .{ ansi.BRIGHT_GREEN ++ ansi.BOLD, ansi.RESET, github_info.license, ansi.RESET });
    std.debug.print("{s}version{s}: {s}{s}{s}\n", .{ ansi.BRIGHT_GREEN ++ ansi.BOLD, ansi.RESET, ansi.BOLD ++ ansi.BRIGHT_YELLOW, version, ansi.RESET });
    std.debug.print("{s}repository{s}: https://github.com/{s}{s}\n", .{ ansi.BRIGHT_GREEN ++ ansi.BOLD, ansi.RESET, repo.repo_full_name, ansi.RESET });
    std.debug.print("{s}zigistry.dev{s}: https://zigistry.dev/{s}/{s}/{s}{s}\n", .{ ansi.BRIGHT_GREEN ++ ansi.BOLD, ansi.RESET, "packages", "github", repo.repo_full_name, ansi.RESET });
}

pub fn update_packages(_: std.mem.Allocator) !void {
    // const file = try std.fs.cwd().openFile("./build.zig.zon", .{});
    // defer file.close();

    // // Read entire file into memory
    // const data = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    // defer allocator.free(data);

    // const parser = try std.zon.parse.fromSlice(std.zon.Serializer, allocator, data, .{}, .{});
    // parser.beginStruct(.{});
}

pub fn install_app(_: types.repository, _: std.mem.Allocator) !void {
    std.debug.print("{s}Installing apps, Comming soon!{s}", .{ ansi.BOLD ++ ansi.BRIGHT_GREEN, ansi.RESET });
    // const d = try hfs.fetch_versions(repo_name, allocator);

    // for (d.items, 1..) |value, i| {
    //     std.debug.print("{}){s} {s}{s}\n", .{ i, ansi.BOLD, value, ansi.RESET });
    // }

    // outer: while (true) {
    //     std.debug.print("{s}>>>{s} ", .{ ansi.BRIGHT_CYAN, ansi.RESET });
    //     var buf: [16]u8 = undefined;
    //     const len = try stdin.read(&buf);
    //     var input = buf[0..len];
    //     if (input.len > 0 and (input[input.len - 1] == '\n' or input[input.len - 1] == '\r')) {
    //         input = input[0 .. input.len - 1];
    //     }
    //     if (input.len == 0) {
    //         std.debug.print("{s}Error:{s} No input entered.\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
    //         continue :outer;
    //     }
    //     for (input) |char| {
    //         if (!std.ascii.isDigit(char)) {
    //             std.debug.print("{s}Error:{s} Non charater input recieved.\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
    //             continue :outer;
    //         }
    //     }
    //     const number = try std.fmt.parseInt(u16, input, 10);
    //     if (number < 1 or number > d.items.len) {
    //         std.debug.print("{s}Error:{s} Number selection is out of range.\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
    //         continue :outer;
    //     }
    //     const items = d.items;

    //     const tag_to_install = switch (number) {
    //         1 => null,
    //         else => items[number - 1],
    //     };
    //     var iter = std.mem.splitScalar(u8, repo_name, '/');
    //     _ = iter.next().?;
    //     std.debug.print("{s}Installing application: {s}{s}{s}\n", .{ ansi.BRIGHT_YELLOW, ansi.UNDERLINE, items[number - 1], ansi.RESET });
    //     const sh = try std.fmt.allocPrint(std.heap.c_allocator,
    //         \\TMP_DIR=$(mktemp -d) &&
    //         \\echo "Created: $TMP_DIR" &&
    //         \\cd "$TMP_DIR" || exit 1 &&
    //         \\git clone https://github.com/{s}.git --depth=1 &&
    //         \\cd {s} || exit 1
    //     , .{ repo_name, iter.next().? });
    //     var process = std.process.Child.init(&[_][]const u8{ "sh", "-c", sh }, std.heap.c_allocator);
    //     var term = try process.spawnAndWait();
    //     switch (term.Exited) {
    //         0 => {},
    //         1 => {
    //             std.debug.print("{s}Zig fetch returned an error. The process returned 1 exit code.{s}\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
    //             return;
    //         },
    //         else => {
    //             std.debug.print("{s}Zig fetch returned an unknown error. It returned {} exit code.{s}\n", .{ ansi.RED ++ ansi.BOLD, term.Exited, ansi.RESET });
    //             return;
    //         },
    //     }
    //     if (tag_to_install) |tag_to_install_not_null| {
    //         process = std.process.Child.init(&[_][]const u8{ "git", "checkout", tag_to_install_not_null }, std.heap.c_allocator);
    //         term = try process.spawnAndWait();
    //         switch (term.Exited) {
    //             0 => {},
    //             else => {
    //                 std.debug.print("{s}zyg wasn't able to git checkout!!! How?. Error code returned: {}{s}\n", .{ ansi.RED ++ ansi.BOLD, term.Exited, ansi.RESET });
    //                 return;
    //             },
    //         }
    //     }
    //     process = std.process.Child.init(&[_][]const u8{ "zig", "build", "install", "--prefix", "$HOME/.local/zyg" }, std.heap.c_allocator);
    //     term = try process.spawnAndWait();

    //     switch (term.Exited) {
    //         0 => std.debug.print("{s}Successfully installed application {s}.{s}\n", .{ ansi.BRIGHT_GREEN ++ ansi.BOLD, repo_name, ansi.RESET }),
    //         1 => {
    //             std.debug.print("{s}Zig fetch returned an error. The process returned 1 exit code.{s}\n", .{ ansi.RED ++ ansi.BOLD, ansi.RESET });
    //             return;
    //         },
    //         else => {
    //             std.debug.print("{s}Zig fetch returned an unknown error. It returned {} exit code.{s}\n", .{ ansi.RED ++ ansi.BOLD, term.Exited, ansi.RESET });
    //             return;
    //         },
    //     }

    //     std.debug.print("Completing...\n", .{});
    //     const path_export =
    //         \\if [[ ":$PATH:" != *":$HOME/.local/bin/zigp:"* ]]; then
    //         \\    echo 'export PATH="$HOME/.local/bin/zigp:$PATH"' >> $HOME/.bashrc 2>/dev/null || true
    //         \\    echo 'export PATH="$HOME/.local/bin/zigp:$PATH"' >> $HOME/.zshrc 2>/dev/null || true
    //         \\    echo "Added $HOME/.local/bin/zigp to your PATH (will apply on next shell start)"
    //         \\fi
    //         \\
    //     ;

    //     process = std.process.Child.init(&[_][]const u8{ "sh", "-c", path_export }, std.heap.c_allocator);
    //     term = try process.spawnAndWait();

    //     switch (term.Exited) {
    //         0 => std.debug.print("Completing...", .{}),
    //         else => std.debug.print("Error while exporting app to PATH.", .{}),
    //     }
    //     break;
    // }
}
