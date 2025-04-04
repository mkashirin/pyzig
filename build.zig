const std = @import("std");

pub fn build(b: *std.Build) void {
    const python_exe = pythonExe(b);
    var python_config = PythonConfig.init(b.allocator, python_exe);

    const test_step = b.step("test", "Run unit tests");

    var zigmodule = PythonModule.init(
        b,
        python_config.standardPythonConfigOptions(),
        .{
            .name = "pyzig.zigmodule",
            .root_source_file = b.path("src/zigmodule.zig"),
            .target = b.standardTargetOptions(.{}),
        },
    );
    const check = b.step("check", "Check if module compiles");
    check.dependOn(zigmodule.install_step);
    zigmodule.install(test_step);
}

fn pythonExe(b: *std.Build) []const u8 {
    return exe: {
        if (b.option(
            []const u8,
            "python-exe",
            "Python executable to use",
        )) |exe| {
            break :exe exe;
        } else {
            break :exe "python3";
        }
    };
}

const PythonConfig = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    python_exe: []const u8,

    fn init(allocator: std.mem.Allocator, python_exe: []const u8) Self {
        return .{ .allocator = allocator, .python_exe = python_exe };
    }

    fn standardPythonConfigOptions(self: *Self) PythonConfigOptions {
        return .{
            .libpython = self.getLibpython(),
            .python_include_dir = self.getPythonIncludeDir(),
            .python_lib_dir = self.getPythonLibDir(),
            .python_hexversion = self.getPythonHexversion(),
        };
    }

    fn getLibpython(self: *Self) []const u8 {
        const ldlibrary = execPythonCode(
            self.allocator,
            self.python_exe,
            "import sysconfig; print(sysconfig.get_config_var('LDLIBRARY'), end='')",
        ) catch @panic("Could not resolve libpython");

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

    fn getPythonIncludeDir(self: *Self) []const u8 {
        return execPythonCode(
            self.allocator,
            self.python_exe,
            "import sysconfig; print(sysconfig.get_path('include'), end='')",
        ) catch @panic("Could not resolve Python include directory");
    }

    fn getPythonLibDir(self: *Self) []const u8 {
        return execPythonCode(
            self.allocator,
            self.python_exe,
            "import sysconfig; print(sysconfig.get_config_var('LIBDIR'), end='')",
        ) catch @panic("Could not resolve Python lib directory");
    }

    fn getPythonHexversion(self: *Self) []const u8 {
        return execPythonCode(
            self.allocator,
            self.python_exe,
            "import sys; print(f'{sys.hexversion & 0xFFFF0000:#010x}', end='')",
        ) catch @panic("Could not resolve Python hexversion");
    }
};

const PythonConfigOptions = struct {
    libpython: []const u8,
    python_include_dir: []const u8,
    python_lib_dir: []const u8,
    python_hexversion: []const u8,
};

fn execPythonCode(
    allocator: std.mem.Allocator,
    python_exe: []const u8,
    code: []const u8,
) ![]const u8 {
    const result = try std.process.Child.run(.{
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

const PythonModule = struct {
    const Self = @This();
    b: *std.Build,
    install_step: *std.Build.Step,
    run_tests: *std.Build.Step,

    fn init(
        b: *std.Build,
        config: PythonConfigOptions,
        module: PythonModuleOptions,
    ) PythonModule {
        _ = generateCImport(config.python_hexversion) catch {
            @panic("Could not read Python hexversion");
        };

        const mod = b.addSharedLibrary(.{
            .name = module.name,
            .root_source_file = module.root_source_file,
            .target = module.target,
            .optimize = module.optimize,
            .link_libc = module.link_libc,
        });
        mod.addIncludePath(.{ .cwd_relative = config.python_include_dir });
        mod.linker_allow_shlib_undefined = true;
        const mod_install = b.addInstallFileWithDir(
            mod.getEmittedBin(),
            .{ .custom = ".." },
            libraryDestRelPath(b.allocator, module.name) catch @panic("OOM"),
        );

        const mod_unit_tests = b.addTest(.{
            .root_source_file = module.root_source_file,
            .target = module.target,
            .optimize = module.optimize,
        });
        mod_unit_tests.linkSystemLibrary(config.libpython);
        mod_unit_tests.addIncludePath(.{
            .cwd_relative = config.python_include_dir,
        });
        mod_unit_tests.addLibraryPath(.{
            .cwd_relative = config.python_lib_dir,
        });
        const run_mod_unit_tests = b.addRunArtifact(mod_unit_tests);

        return .{
            .b = b,
            .install_step = &mod_install.step,
            .run_tests = &run_mod_unit_tests.step,
        };
    }

    fn install(self: *Self, test_step: *std.Build.Step) void {
        self.b.getInstallStep().dependOn(self.install_step);
        test_step.dependOn(self.run_tests);
    }
};

const PythonModuleOptions = struct {
    name: []const u8,
    root_source_file: std.Build.LazyPath,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode = .ReleaseSafe,
    link_libc: bool = true,
};

fn generateCImport(hexver: []const u8) ![]const u8 {
    var output_file = try std.fs.cwd().createFile("src/c.zig", .{});
    defer output_file.close();

    var source_buf: [512]u8 = undefined;
    const fmt_source = try std.fmt.bufPrint(&source_buf,
        \\pub usingnamespace @cImport({{
        \\    @cDefine("Py_LIMITED_API", "{s}");
        \\    @cDefine("PY_SSIZE_T_CLEAN", {{}});
        \\    @cInclude("Python.h");
        \\    @cInclude("structmember.h");
        \\}});
    , .{hexver});
    try output_file.writeAll(fmt_source);

    return fmt_source;
}

fn libraryDestRelPath(
    allocator: std.mem.Allocator,
    name: []const u8,
) ![]const u8 {
    const suffix = ".so";
    const dest_path = try allocator.alloc(u8, name.len + suffix.len);

    // Take the module name, replace dots for slashes.
    @memcpy(dest_path[0..name.len], name);
    std.mem.replaceScalar(u8, dest_path[0..name.len], '.', '/');

    // Append the suffix
    @memcpy(dest_path[name.len..], suffix);

    return dest_path;
}
