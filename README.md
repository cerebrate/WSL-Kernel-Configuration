# WSL-Kernel-Configuration
My personal configuration for building WSL kernels.

## Installation

Clone this repo...

```
gh repo clone cerebrate/WSL-Kernel-Configuration
```

...into a directory peer to the `linux` directory of a fresh kernel tree.

From inside the WSL-Kernel-Configuration directory, run:

```
patch-peer-kernel
```

The first run in a given kernel tree applies the patches in `patches/` and leaves a `.wsl-patches-applied` flag file in `../linux`. Later runs skip the patches and only copy the configuration files. To apply the patches again, reset the kernel tree and delete the flag file.

Then switch to the `../linux` directory and follow [Building the kernel](#building-the-kernel) below.

If you change `.config` or `localversion`, for example using `make xconfig`, do not forget to copy them back to `../WSL-Kernel-Configuration` afterwards. The `pull-configuration` script does this.

## Building the kernel

A build produces two sets of outputs:

- **Debian packages**: `linux-image`, `linux-headers`, `linux-libc-dev` and the `-dbg` debug-symbols package.
- **WSL files**: a kernel image (`bzImage`) and a modules disk (`modules.vhdx`) for the `kernel` and `kernelModules` settings in `.wslconfig`.

All commands below run in bash or zsh inside WSL, from the `../linux` directory unless stated otherwise.

### Prerequisites

On Debian:

```
sudo apt install build-essential bc bison flex dwarves kmod cpio rsync python3 \
    libelf-dev libdw-dev libssl-dev debhelper dpkg-dev e2fsprogs qemu-utils
```

### 1. Prepare the tree

1. For a new release, bump `localversion` in this repo first. It holds a suffix of the form `-YYYYMMDDNN`.
2. Run `./patch-peer-kernel` from this repo. It applies the patches the first time, then copies `.config` and `localversion`.
3. In `../linux`, bring the configuration up to date. On a new kernel version this sets any new options to their defaults:

   ```
   make olddefconfig
   ```

4. If that changed `.config`, copy it back to this repo:

   ```
   (cd ../WSL-Kernel-Configuration && ./pull-configuration)
   ```

### 2. Build the kernel and the Debian packages

```
make -j$(nproc) deb-pkg
```

This builds the kernel and modules in the tree; `deb-pkg` doesn't clean first. It then packages them.

- **Where the packages go:** the `.deb` files, and the source package that `deb-pkg` also produces, are written to the directory above `linux`.
- **Package names:** patch 01 lowercases the package names, because Debian package names can't contain the uppercase `WSL2`.
- **Expected warning:** the patches are uncommitted changes in `../linux`, and the `localversion` file is untracked. As a result, `deb-pkg` prints a warning that the working tree has a diff from HEAD and also untracked files. This is expected.
- **`-dirty` suffix:** for the same reason, the kernel release string ends in `-dirty`, e.g. `7.3.0-2026111401-microsoft-custom-WSL2-dirty`.

If you only want the WSL files, `make -j$(nproc)` builds the same kernel and modules without packaging them.

### 3. Build the WSL kernel and modules files

The steps below build the WSL modules disk by hand. They follow the manual process in Microsoft's [WSL2-Linux-Kernel README](https://github.com/microsoft/WSL2-Linux-Kernel#build-instructions), because Microsoft's `gen_artifacts_vhdx.sh` script isn't in the upstream tree. There are two differences:

- **Output location:** everything is collected outside the kernel tree, in `../wsl-build/<release>`.
- **Orphan file:** the ext4 `orphan_file` feature is removed from the modules image before it is converted. Without this step, WSL won't boot (see the note after step 3d).

#### 3a. Collect the kernel, modules, headers and perf

```
release=$(make -s kernelrelease)
out="$(cd .. && pwd)/wsl-build/$release"
rm -rf "$out" && mkdir -p "$out"

cp arch/x86/boot/bzImage "$out/bzImage"
make INSTALL_MOD_PATH="$out/modules" INSTALL_MOD_STRIP=1 modules_install
make INSTALL_HDR_PATH="$out/headers" headers_install
make -j$(nproc) -C tools/perf NO_JEVENTS=1 NO_JVMTI=1 NO_LIBTRACEEVENT=1 \
    DESTDIR="$out/perf" prefix=/ install
```

`INSTALL_MOD_STRIP=1` strips debug info from the modules. The `linux-image` package does the same, and the full symbols are in the `-dbg` package. Without it, the modules disk is far larger.

#### 3b. Stage them in the layout WSL expects

WSL expects the layout `<release>/{modules,linux-headers,perf}`:

```
staging="$out/staging"
mkdir -p "$staging/$release/linux-headers"
cp -r "$out/modules/lib/modules/$release" "$staging/$release/modules"
rm -f "$staging/$release/modules/build" "$staging/$release/modules/source"
cp -r "$out/headers/." "$staging/$release/linux-headers"
cp -r "$out/perf" "$staging/$release/perf"
```

#### 3c. Build the ext4 image and remove its orphan file

Create the image with 256 MiB of slack, then remove the orphan file:

```
image_size=$(du -bs "$staging" | awk '{print $1}')
image_size=$((image_size + 256 * 1024 * 1024))
mke2fs -L '' -d "$staging" -N $(( $(find "$staging" | wc -l) + 4096 )) \
    -b 1024 -t ext4 "$out/modules.img" $((image_size / 1024))

tune2fs -O '^orphan_file' "$out/modules.img"
dumpe2fs -h "$out/modules.img" | grep 'Filesystem features'
```

The `dumpe2fs` output must not list `orphan_file`. Keep the quotes around `'^orphan_file'`: zsh with `extendedglob` set treats an unquoted `^` as a glob operator.

#### 3d. Convert to VHDX and clean up

```
qemu-img convert -O vhdx "$out/modules.img" "$out/modules.vhdx"
rm -rf "$out/modules.img" "$out/staging" "$out/modules" "$out/headers" "$out/perf"
```

`$out` now holds just `bzImage` and `modules.vhdx`.

> **Why remove the orphan file?** Since late 2025, the kernel refuses to mount an ext4 filesystem whose orphan file is larger than 512 filesystem blocks. With `-b 1024`, that limit is 512 KiB. That change came in commits 0a6ce20 and 7c11c56. e2fsprogs 1.47.4, the current Debian version, hasn't caught up. Its `mke2fs` makes the orphan file about 1 KiB per MiB of filesystem, so any modules image over about 512 MiB exceeds the limit. Removing the feature is harmless on smaller images too, so do it every time. WSL then mounts the modules disk at boot and fails, logging something like:
>
> ```
> EXT4-fs (sdb): orphan file too big: 975872
> WSL (1 - mini_init) ERROR: UtilMount:1846: mount(/dev/sdb, /modules, ext4, 0x1, <null>) failed 117
> ```
>
> After that, the VM shuts down. The modules disk is mounted read-only and never accumulates orphan inodes, so it can do without the feature. For the full story, see [You Can't Build 'Em Like You Used To](https://randombytes.substack.com/p/you-cant-build-em-like-you-used-to).

### 4. Install in WSL

1. **Copy the files to Windows.** Copy `bzImage` and `modules.vhdx` to a folder on the Windows side. Give each copy a release-specific name, so you never overwrite the files the running VM is using and can go back to the previous kernel by editing `.wslconfig`:

   ```
   win=/mnt/c/Users/<you>/WSL     # any Windows folder
   cp "$out/bzImage" "$win/bzImage-$release"
   cp "$out/modules.vhdx" "$win/modules-$release.vhdx"
   ```

2. **Point `.wslconfig` at them.** Edit `[wsl2]` in `%UserProfile%\.wslconfig`. The paths must be absolute Windows paths with escaped backslashes:

   ```
   [wsl2]
   kernel=C:\\Users\\<you>\\WSL\\bzImage-<release>
   kernelModules=C:\\Users\\<you>\\WSL\\modules-<release>.vhdx
   ```

3. **Restart WSL.** Run `wsl --shutdown` from Windows, start a distro, and check that `uname -r` shows the new release.

**If the new kernel doesn't boot:**

- Add `debugConsoleLogFile=C:\\path\\to\\wsl-console.log` under `[wsl2]` to capture the kernel console.
- To get going again, comment out the `kernel` and `kernelModules` lines and run `wsl --shutdown`.

**Fixing an older `modules.vhdx` in place:** a disk built without step 3c can be fixed instead of rebuilt.

1. With a working kernel, run `wsl --mount --vhd C:\path\to\modules.vhdx --bare` from Windows.
2. Inside WSL, find the new disk with `lsblk` (call it `/dev/sdX`) and run:

   ```
   sudo tune2fs -O '^orphan_file' /dev/sdX
   ```

3. Detach the disk with `wsl --unmount C:\path\to\modules.vhdx`.

