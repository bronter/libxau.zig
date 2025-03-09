const std = @import("std");

const LinkMode = if (@hasField(std.builtin.LinkMode, "static")) std.builtin.LinkMode else std.Build.Step.Compile.Linkage;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(LinkMode, "linkage", "whether to statically or dynamically link the library") orelse @as(LinkMode, if (target.result.isGnuLibC()) .dynamic else .static);

    const libxauSource = b.dependency("libxau", .{});
    const xorgprotoSource = b.dependency("xorgproto", .{});

    const libxau_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const libxau = b.addLibrary(.{
        .name = "Xau",
        .root_module = libxau_mod,
        .linkage = linkage,
    });

    libxau.addIncludePath(libxauSource.path("include"));
    libxau.addIncludePath(xorgprotoSource.path("include"));

    libxau.addCSourceFiles(.{
        .root = libxauSource.path("."),
        .files = &.{
            "AuDispose.c",
            "AuFileName.c",
            "AuGetAddr.c",
            "AuGetBest.c",
            "AuLock.c",
            "AuRead.c",
            "AuUnlock.c",
            "AuWrite.c",
        },
    });

    {
        const headers: []const []const u8 = &.{
            "X11/Xauth.h",
        };

        for (headers) |header| {
            libxau.installHeader(libxauSource.path(b.pathJoin(&.{ "include", header })), header);
        }
    }

    b.installArtifact(libxau);
}
