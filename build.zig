const std = @import("std");

pub fn build(b: *std.Build) void {
    const name = "pyzig.pyzig";
    const root_source_file = b.path("src/root.zig");
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const link_libc = true;

    const python_exe = blk: {
        if (b.option(
            []const u8,
            "python-exe",
            "Python executable to use",
        )) |exe| {
            break :blk exe;
        } else {
            break :blk "python3";
        }
    };
    const libpython = getLibpython(
        b.allocator,
        python_exe,
    ) catch @panic("Could not find libpython");
    const python_include_dir = execPythonCode(
        b.allocator,
        python_exe,
        "import sysconfig; print(sysconfig.get_path('include'), end='')",
    ) catch @panic("Could not resolve Python include directory");
    const python_lib_dir = execPythonCode(
        b.allocator,
        python_exe,
        "import sysconfig; print(sysconfig.get_config_var('LIBDIR'), end='')",
    ) catch @panic("Could not resolve Python lib directory");

    const lib = b.addSharedLibrary(.{
        .name = name,
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
        .link_libc = link_libc,
    });
    lib.addIncludePath(.{ .cwd_relative = python_include_dir });
    lib.linker_allow_shlib_undefined = true;

    const install = b.addInstallFileWithDir(
        lib.getEmittedBin(),
        .{ .custom = ".." },
        libDestRelPath(b.allocator, name) catch @panic("OOM"),
    );
    b.getInstallStep().dependOn(&install.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = python_include_dir });
    lib_unit_tests.linkSystemLibrary(libpython);
    lib_unit_tests.addLibraryPath(.{ .cwd_relative = python_lib_dir });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

fn libDestRelPath(allocator: std.mem.Allocator, name: []const u8) ![]const u8 {
    const suffix = ".so";
    const dest_path = try allocator.alloc(u8, name.len + suffix.len);

    // Take the module name, replace dots for slashes.
    @memcpy(dest_path[0..name.len], name);
    std.mem.replaceScalar(u8, dest_path[0..name.len], '.', '/');

    // Append the suffix
    @memcpy(dest_path[name.len..], suffix);

    return dest_path;
}

fn getLibpython(
    allocator: std.mem.Allocator,
    python_exe: []const u8,
) ![]const u8 {
    const ldlibrary = try execPythonCode(
        allocator,
        python_exe,
        "import sysconfig; print(sysconfig.get_config_var('LDLIBRARY'), end='')",
    );

    var libname = ldlibrary;

    // Strip `libpython3.11.a.so` to `python3.11.a.so`
    if (std.mem.eql(u8, ldlibrary[0..3], "lib")) {
        libname = libname[3..];
    }

    // Strip `python3.11.a.so` to `python3.11.a`
    const last_index = std.mem.lastIndexOfScalar(
        u8,
        libname,
        '.',
    ) orelse libname.len;
    libname = libname[0..last_index];

    return libname;
}

fn execPythonCode(
    allocator: std.mem.Allocator,
    python_exe: []const u8,
    code: []const u8,
) ![]const u8 {
    const result = try runProcess(.{
        .allocator = allocator,
        .argv = &.{ python_exe, "-c", code },
    });
    if (result.term.Exited != 0) {
        std.debug.print(
            "Failed to execute {s}:\n{s}\n",
            .{ code, result.stderr },
        );
        std.process.exit(1);
    }
    allocator.free(result.stderr);
    return result.stdout;
}

fn getStdOutput(
    allocator: std.mem.Allocator,
    argv: []const []const u8,
) ![]const u8 {
    const result = try runProcess(.{ .allocator = allocator, .argv = argv });
    if (result.term.Exited != 0) {
        std.debug.print(
            "Failed to execute {any}:\n{s}\n",
            .{ argv, result.stderr },
        );
        std.process.exit(1);
    }
    allocator.free(result.stderr);
    return result.stdout;
}

const runProcess = std.process.Child.run;
