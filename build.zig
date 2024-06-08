const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "TinyEMU",
        .target = target,
        .optimize = optimize,
    });
    inline for (&.{ "riscv_cpu32", "riscv_cpu64", "riscv_cpu128" }) |name| {
        exe.addObject(rv_cpu(b, .{
            .name = name,
            .target = target,
            .optimize = optimize,
        }));
    }
    exe.addIncludePath(.{ .cwd_relative = "." });
    exe.addCSourceFiles(.{
        .files = src,
        .flags = &.{
            "-Wall",
        },
    });
    if (exe.rootModuleTarget().cpu.arch.isX86()) {
        exe.addCSourceFiles(.{
            .files = &.{
                "x86_cpu.c",
                "x86_machine.c",
                "ide.c",
                "pckbd.c",
                "ps2.c",
                "vga.c",
                "vmmouse.c",
            },
        });
        exe.defineCMacro("CONFIG_X86EMU", null);
    } else if (exe.rootModuleTarget().isWasm()) {
        exe.addCSourceFile(.{
            .file = .{
                .cwd_relative = "jsemu.c",
            },
        });
    }
    if (exe.rootModuleTarget().abi != .msvc)
        exe.defineCMacro("_GNU_SOURCE", null);

    exe.defineCMacro("_FILE_OFFSET_BITS", "64");
    exe.defineCMacro("_LARGEFILE_SOURCE", null);
    exe.defineCMacro("CONFIG_SLIRP", null);
    exe.defineCMacro("CONFIG_FS_NET", null);
    exe.defineCMacro("CONFIG_COMPRESSED_INITRAMFS", null);
    exe.defineCMacro("CONFIG_VERSION", "\"2019-02-10\"");

    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("z");
    exe.linkSystemLibrary("curl");
    exe.linkSystemLibrary("crypto");
    exe.linkLibC();

    b.installArtifact(exe);
}

fn rv_cpu(b: *std.Build, options: struct {
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
}) *std.Build.Step.Compile {
    const rv = b.addObject(.{
        .name = options.name,
        .target = options.target,
        .optimize = options.optimize,
    });
    rv.addCSourceFile(.{
        .file = .{
            .cwd_relative = "riscv_cpu.c",
        },
    });
    rv.defineCMacro("CONFIG_RISCV_MAX_XLEN", "128");
    if (std.mem.endsWith(u8, options.name, "32")) {
        rv.defineCMacro("MAX_XLEN", "32");
    } else if (std.mem.endsWith(u8, options.name, "64")) {
        rv.defineCMacro("MAX_XLEN", "64");
    } else {
        rv.defineCMacro("MAX_XLEN", "128");
    }
    rv.linkLibC();

    return rv;
}

const src = &.{
    "aes.c",
    "block_net.c",
    // "build_filelist.c",
    "fs_utils.c",
    "cutils.c",
    "compress.c",
    "elf.c",
    "fs.c",
    "fs_disk.c",
    "fs_net.c",
    "fs_wget.c",
    "iomem.c",
    "json.c",
    "machine.c",
    "pci.c",
    "riscv_machine.c",
    "sdl.c",
    "sha256.c",
    "simplefb.c",
    "slirp/bootp.c",
    "slirp/cksum.c",
    "slirp/if.c",
    "slirp/ip_icmp.c",
    "slirp/ip_input.c",
    "slirp/ip_output.c",
    "slirp/mbuf.c",
    "slirp/misc.c",
    "slirp/sbuf.c",
    "slirp/slirp.c",
    "slirp/socket.c",
    "slirp/tcp_input.c",
    "slirp/tcp_output.c",
    "slirp/tcp_subr.c",
    "slirp/tcp_timer.c",
    "slirp/udp.c",
    "softfp.c",
    // "splitimg.c",
    "temu.c",
    "virtio.c",
};
