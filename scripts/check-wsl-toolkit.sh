#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [kernel-tree]" >&2
}

if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

kernel_tree=${1:-$PWD}
if [[ ! -d "$kernel_tree" ]]; then
  echo "Kernel tree does not exist: $kernel_tree" >&2
  exit 1
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
workspace_root=$(cd "$script_dir/.." && pwd)
patch_file="$workspace_root/patches/mkdebian-uppercase-kernelrelease.patch"
local_upstream="$workspace_root/scripts/gen-modules-vhdx-msft-upstream.sh"
msft_ref=${MSFT_WSL_REF:-linux-msft-wsl-6.6.y}
msft_url="https://raw.githubusercontent.com/microsoft/WSL2-Linux-Kernel/${msft_ref}/Microsoft/scripts/gen_modules_vhdx.sh"

for cmd in curl sha256sum patch grep; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing required command: $cmd" >&2
    exit 1
  }
done

if [[ ! -f "$patch_file" ]]; then
  echo "Missing patch file: $patch_file" >&2
  exit 1
fi

if [[ ! -f "$local_upstream" ]]; then
  echo "Missing local upstream helper snapshot: $local_upstream" >&2
  exit 1
fi

tmp_upstream=$(mktemp)
trap 'rm -f "$tmp_upstream"' EXIT

echo "Checking Microsoft helper freshness (ref: $msft_ref)..."
if curl -fsSL "$msft_url" -o "$tmp_upstream"; then
  remote_hash=$(sha256sum "$tmp_upstream" | awk '{print $1}')
  local_hash=$(sha256sum "$local_upstream" | awk '{print $1}')
  if [[ "$remote_hash" == "$local_hash" ]]; then
    echo "  OK: vendored Microsoft helper snapshot matches remote."
  else
    echo "  WARN: remote Microsoft helper changed."
    echo "        local snapshot:  $local_hash"
    echo "        remote snapshot: $remote_hash"
    echo "        review/update:   $local_upstream"
  fi
else
  echo "  WARN: unable to fetch Microsoft helper script from: $msft_url"
fi

echo "Checking Debian mkdebian patch drift..."
mkdebian="$kernel_tree/scripts/package/mkdebian"
if [[ ! -f "$mkdebian" ]]; then
  echo "  ERROR: missing target file: $mkdebian"
  exit 1
fi

if grep -q "krel_pkg=.*tr '\\[:upper:\\]' '\\[:lower:\\]'" "$mkdebian"; then
  echo "  OK: patch markers already present in kernel tree."
elif patch -d "$kernel_tree" -p1 --dry-run --silent < "$patch_file"; then
  echo "  OK: patch still applies cleanly."
else
  echo "  WARN: patch no longer applies cleanly and markers were not found."
  echo "        regenerate/update: $patch_file"
fi

echo "Toolkit check complete."
