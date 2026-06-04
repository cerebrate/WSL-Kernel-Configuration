#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <modules-root> <kernelrelease> <output-vhdx>" >&2
}

if [[ $# -ne 3 ]]; then
  usage
  exit 1
fi

if [[ ${EUID} -ne 0 ]]; then
  echo "This script requires root (loop device + mount operations)." >&2
  exit 1
fi

modules_root=$1
kernelrelease=$2
output_vhdx=$3
modules_dir="$modules_root/lib/modules/$kernelrelease"

if [[ ! -d "$modules_dir" ]]; then
  echo "Missing modules directory: $modules_dir" >&2
  exit 1
fi

if [[ -e "$output_vhdx" ]]; then
  echo "Refusing to overwrite existing file: $output_vhdx" >&2
  exit 1
fi

for cmd in du awk mktemp truncate losetup mkfs.ext4 mount cp qemu-img umount; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing required command: $cmd" >&2
    exit 1
  }
done

tmp_dir=$(mktemp -d)
loop_dev=""
mnt_dir="$tmp_dir/modules_img"

cleanup() {
  set +e
  if mountpoint -q "$mnt_dir" 2>/dev/null; then
    umount "$mnt_dir"
  fi
  if [[ -n "$loop_dev" ]]; then
    losetup -d "$loop_dev"
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

# Add 256MiB slack to module payload size.
modules_size=$(du -bs "$modules_root" | awk '{print $1}')
modules_size=$((modules_size + 256 * 1024 * 1024))

img="$tmp_dir/modules.img"
truncate -s "$modules_size" "$img"

loop_dev=$(losetup --find --show "$img")
mkfs.ext4 -F "$loop_dev" >/dev/null
mkdir -p "$mnt_dir"
mount "$loop_dev" "$mnt_dir"
chmod a+rw "$mnt_dir"

cp -a "$modules_dir/." "$mnt_dir/"
umount "$mnt_dir"
losetup -d "$loop_dev"
loop_dev=""

qemu-img convert -O vhdx "$img" "$output_vhdx"

if [[ -n "${SUDO_USER:-}" ]]; then
  chown "$SUDO_USER:$SUDO_USER" "$output_vhdx"
fi
