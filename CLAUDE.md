# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Configuration, patches, and helper scripts for building custom Linux kernels (and modules) for WSL2. There is no source code to compile here; the kernel source lives in a **peer directory** `../linux` (a fresh kernel tree), and this repo is copied into / pulled back from it. Both helper scripts use hard-coded relative paths (`../linux`, `../WSL-Kernel-Configuration`), so they must be run from inside this repo's directory, and the directory must keep the name `WSL-Kernel-Configuration`.

## Workflow

```sh
./patch-peer-kernel      # apply patches/ once, then copy .config and localversion into ../linux
cd ../linux
make xconfig             # optional: adjust configuration
make deb-pkg             # build Debian kernel/header packages
cd ../WSL-Kernel-Configuration
./pull-configuration     # copy ../linux/.config and localversion back here
```

The README's "Building the kernel" section is the full procedure: Debian packages plus the WSL `bzImage` and `modules.vhdx`. When building `modules.vhdx`, the step that removes the ext4 `orphan_file` feature (`tune2fs -O '^orphan_file'`) is required. Without it, current kernels refuse to mount the modules disk and WSL fails to boot. Keep the quotes: zsh's `extendedglob` would otherwise glob `^orphan_file`.

Any config change made in `../linux` (via `make xconfig`, `make olddefconfig`, etc.) is lost unless `pull-configuration` is run afterwards. There are no tests or linters; "verifying" a change means building the kernel in `../linux`.

## Key files

- `.config` — full kernel config (x86_64, currently Linux 7.2, built with Debian gcc). Edit it through kconfig in `../linux` and pull it back rather than hand-editing, so dependent symbols stay consistent. Commit messages often cite the reason for a config change (e.g. an upstream microsoft/WSL issue).
- `localversion` — release suffix of the form `-YYYYMMDDNN` (leading dash required). Bump it for each new kernel release. It combines with `CONFIG_LOCALVERSION="-microsoft-custom-WSL2"` in `.config` to give a release string like `7.2.0-2026111401-microsoft-custom-WSL2`. The uppercase `WSL2` is needed for WSL detection at runtime.
- `patches/` — kernel patches to apply to `../linux`:
  - `01-lowercase-deb-package-names.patch` changes `scripts/package/{mkdebian,builddeb}` so Debian package names are lowercased while the kernel release keeps `WSL2` uppercase. Upstream still needs this as of 7.3. It is a plain diff.
  - `02-swiotlb-hyperv.patch` and `03-pci-hv-reserve.patch` are a `git format-patch` series from Microsoft's WSL kernel branch, now ported to 7.3. 03 depends on 02. They add the dedicated Hyper-V VPCI swiotlb pool behind WSL's virtio-performance feature. The 7.3 port carries local code changes (`cc_shared` handling) beyond Microsoft's version. `patches/02-03-README.md` explains the purpose, config requirements and porting notes. Read it before re-porting.

## How `patch-peer-kernel` applies patches

- It applies every `patches/*.patch` in name order with `git apply`, which leaves the changes uncommitted in `../linux`. Name new patches with the next number prefix.
- It applies them one at a time, because `git apply` given several patches at once is not all-or-nothing. If any patch fails, it reverts the ones already applied (`git apply -R`), exits non-zero, and copies no config files.
- On success it writes `../linux/.wsl-patches-applied`, which lists the sha256 of each applied patch. While that file exists, later runs skip patching and only copy the config files, so the script can be re-run freely after config edits.
- If the patch files no longer match the recorded checksums, it warns but does not re-apply. To re-apply, reset `../linux` (e.g. `git reset --hard`) and delete the flag file.
- The flag file is a dotfile, which the kernel's `.gitignore` ignores, so it doesn't show up in `git status` or in the source diff `make deb-pkg` generates.
