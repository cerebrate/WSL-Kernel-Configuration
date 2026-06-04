#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [kernel-tree] [yyyymmddvv]" >&2
}

if [[ $# -gt 2 ]]; then
  usage
  exit 1
fi

kernel_tree=$PWD
build_stamp=""

if [[ $# -ge 1 ]]; then
  if [[ "$1" =~ ^[0-9]{10}$ ]]; then
    build_stamp=$1
  else
    kernel_tree=$1
  fi
fi

if [[ $# -eq 2 ]]; then
  build_stamp=$2
fi

if [[ ! -d "$kernel_tree" ]]; then
  echo "Kernel tree does not exist: $kernel_tree" >&2
  exit 1
fi

# Now that kernel_tree is set, check for existing localversion and auto-increment
today=$(date +%Y%m%d)
if [[ -z "$build_stamp" ]]; then
  build_stamp="${today}01"
  
  # Auto-increment if a localversion file exists with today's date
  localversion_check="$kernel_tree/localversion.wsl-build"
  if [[ -f "$localversion_check" ]]; then
    existing=$(cat "$localversion_check" | tr -d '[:space:]' | tr -d '-')
    if [[ "$existing" =~ ^([0-9]{8})([0-9]{2})$ ]]; then
      existing_date="${BASH_REMATCH[1]}"
      existing_ver="${BASH_REMATCH[2]}"
      if [[ "$existing_date" == "$today" ]]; then
        # Increment the version number
        next_ver=$((existing_ver + 1))
        if [[ $next_ver -le 99 ]]; then
          build_stamp=$(printf "%s%02d" "$today" "$next_ver")
        fi
      fi
    fi
  fi
fi

if [[ ! "$build_stamp" =~ ^[0-9]{10}$ ]]; then
  echo "Build stamp must be yyyymmddvv (10 digits), got: $build_stamp" >&2
  exit 1
fi
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
workspace_root=$(cd "$script_dir/.." && pwd)
config_src=${CONFIG_SOURCE:-"$workspace_root/dot-config"}
patch_file=${MKDEBIAN_PATCH_FILE:-"$workspace_root/patches/mkdebian-uppercase-kernelrelease.patch"}
localversion_file=${LOCALVERSION_FILE:-"$kernel_tree/localversion.wsl-build"}

if [[ ! -f "$config_src" ]]; then
  echo "Missing config source: $config_src" >&2
  exit 1
fi

if [[ ! -f "$patch_file" ]]; then
  echo "Missing patch file: $patch_file" >&2
  exit 1
fi

if [[ ! -f "$kernel_tree/scripts/package/mkdebian" ]]; then
  echo "Expected file missing in kernel tree: scripts/package/mkdebian" >&2
  exit 1
fi

cp "$config_src" "$kernel_tree/.config"
printf -- '-%s\n' "$build_stamp" > "$localversion_file"

if grep -q "krel_pkg=.*tr '\\[:upper:\\]' '\\[:lower:\\]'" "$kernel_tree/scripts/package/mkdebian"; then
  echo "mkdebian patch already present."
else
  patch -d "$kernel_tree" -p1 --forward --batch --silent < "$patch_file"
  echo "Applied mkdebian lowercase package-name patch."
fi

echo "Prepared kernel tree: $kernel_tree"
echo "  .config <- $config_src"
echo "  localversion file: $localversion_file ($(cat "$localversion_file"))"
echo "  Note: WSL suffix remains sourced from CONFIG_LOCALVERSION in .config"
echo
echo "You can now tweak config if needed (e.g. make menuconfig)."
