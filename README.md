# WSL Kernel Build Toolkit

This directory holds personal build tooling and artifacts outside the Linux repo.

## Layout

- `dot-config` — your master kernel config.
- `scripts/prepare-wsl-kernel-tree.sh` — copy config, generate date localversion, apply Debian patch.
- `scripts/build-and-collect-wsl-artifacts.sh` — build once with `bindeb-pkg`, create modules VHDX, collect outputs.
- `scripts/gen-modules-vhdx.sh` — hardened VHDX generator used by build script.
- `scripts/gen-modules-vhdx-msft-upstream.sh` — vendored Microsoft upstream helper snapshot for freshness checks.
- `scripts/check-wsl-toolkit.sh` — quick check for upstream helper changes + patch drift.
- `patches/mkdebian-uppercase-kernelrelease.patch` — lowercases package names in `mkdebian`.
- `output/` — final collected artifacts.
- `~/src/wsl-kernel-build/` — transient source snapshot, object/module staging, and package outputs.

## Defaults


- Kernel tree defaults to current working directory for both main scripts.
- Localversion defaults to today in `YYYYMMDDvv` form (`vv=01`), e.g. `2026060101`.
- **Auto-increment behavior**: If a `localversion.wsl-build` file already exists with today's date, the prepare script automatically increments the `vv` suffix (01→02→03, etc.) up to 99, enabling multiple builds per day without manual intervention.
- WSL suffix is **not** added by scripts; it comes from `CONFIG_LOCALVERSION` in `.config`.
- Build script exports a clean source snapshot to `~/src/wsl-kernel-build/linux-src-<ref>-<stamp>` before building, so dirty working trees do not trigger the kernel `mrproper` cleanliness failure.
- Snapshot naming uses git branch/tag/commit plus localversion stamp. The snapshot is auto-cleaned on success (kept on failure for troubleshooting). Associated `.deb`, `.changes`, and `.buildinfo` files in the parent directory are also cleaned.


## Typical workflow

From kernel repo root:

```bash
~/kernel-building/scripts/check-wsl-toolkit.sh
~/kernel-building/scripts/prepare-wsl-kernel-tree.sh
# optional config edits:
# make menuconfig
~/kernel-building/scripts/build-and-collect-wsl-artifacts.sh
```

Artifacts land in:

`~/kernel-building/output/<stamp>/`

with:

- `linux-image-*.deb`
- `linux-headers-*.deb`
- `modules.vhdx`
- `vmlinuz-<kernelrelease>`

## Optional arguments

```bash
# Explicit kernel tree and build stamp
~/kernel-building/scripts/prepare-wsl-kernel-tree.sh /path/to/linux 2026052902

# Explicit kernel tree and jobs
~/kernel-building/scripts/build-and-collect-wsl-artifacts.sh /path/to/linux 8

# Re-collect artifacts without recompiling
~/kernel-building/scripts/build-and-collect-wsl-artifacts.sh --collect-only

# Re-collect without creating modules.vhdx (debug helper issues)
~/kernel-building/scripts/build-and-collect-wsl-artifacts.sh --collect-only --no-vhdx
```

If you pass one numeric argument to either script, it is interpreted as:

- prepare script: build stamp (`yyyymmddvv`)
- build script: job count

## Notes

- `modules.vhdx` generation requires `qemu-img` (`qemu-utils` package) and sudo privileges.
- If `bindeb-pkg` intermittently fails with `/bin/sh: 1: ./scripts/basic/fixdep: Permission denied`, rerun with single-threaded jobs (for example: `~/kernel-building/scripts/build-and-collect-wsl-artifacts.sh /path/to/linux 1`).
