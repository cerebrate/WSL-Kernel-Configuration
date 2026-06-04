#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [--collect-only] [--no-vhdx] [kernel-tree] [jobs]" >&2
}

collect_only=0
skip_vhdx=0
args=()
for arg in "$@"; do
  case "$arg" in
    --collect-only)
      collect_only=1
      ;;
    --no-vhdx)
      skip_vhdx=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      args+=("$arg")
      ;;
  esac
done

if [[ ${#args[@]} -gt 2 ]]; then
  usage
  exit 1
fi

kernel_tree=$PWD
jobs=$(nproc)

if [[ ${#args[@]} -ge 1 ]]; then
  if [[ "${args[0]}" =~ ^[0-9]+$ ]]; then
    jobs=${args[0]}
  else
    kernel_tree=${args[0]}
  fi
fi

if [[ ${#args[@]} -eq 2 ]]; then
  jobs=${args[1]}
fi

if [[ ! -d "$kernel_tree" ]]; then
  echo "Kernel tree does not exist: $kernel_tree" >&2
  exit 1
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
workspace_root=$(cd "$script_dir/.." && pwd)
helper_script="$workspace_root/scripts/gen-modules-vhdx.sh"
patch_file="$workspace_root/patches/mkdebian-uppercase-kernelrelease.patch"
build_workspace="$HOME/src/wsl-kernel-build"
modules_stage="$build_workspace/modules-root"
output_root="$workspace_root/output"
localversion_file="$kernel_tree/localversion.wsl-build"
build_tree="$kernel_tree"
clean_src_dir=""
cleanup_snapshot=0
snapshot_status="kept"

cleanup() {
  rc=$?
  if [[ $cleanup_snapshot -eq 1 ]]; then
    if [[ $rc -eq 0 ]]; then
      rm -rf "$clean_src_dir"
      rm -rf "$modules_stage"
      snapshot_status="removed"
      # Clean up .deb files from parent directory of build tree
      if [[ -n "$clean_src_dir" ]]; then
        find "$(dirname "$clean_src_dir")" -maxdepth 1 -type f \( -name "*.deb" -o -name "*.changes" -o -name "*.buildinfo" \) -delete 2>/dev/null || true
      fi
    else
      snapshot_status="kept (build failed)"
    fi
    echo "Source snapshot: $clean_src_dir ($snapshot_status)"
  fi
}
trap cleanup EXIT

for cmd in make find cp awk sort tail git tar patch; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing required command: $cmd" >&2
    exit 1
  }
done

if [[ ! -x "$helper_script" ]]; then
  echo "Missing executable VHDX helper: $helper_script" >&2
  exit 1
fi

if [[ ! -f "$kernel_tree/.config" ]]; then
  echo "Missing .config in kernel tree: $kernel_tree/.config" >&2
  echo "Run prepare-wsl-kernel-tree.sh first." >&2
  exit 1
fi

if [[ ! -f "$patch_file" ]]; then
  echo "Missing mkdebian patch file: $patch_file" >&2
  exit 1
fi

mkdir -p "$modules_stage" "$output_root" "$build_workspace"
build_marker="$build_workspace/.build-start-marker"
touch "$build_marker"
find_newer_filter=(-newer "$build_marker")

if [[ $collect_only -eq 1 ]]; then
  mapfile -t snapshots < <(find "$build_workspace" -maxdepth 1 -mindepth 1 -type d -name 'linux-src-*' | sort)
  if [[ ${#snapshots[@]} -eq 0 ]]; then
    echo "No prior snapshot found under $build_workspace. Run full build first." >&2
    exit 1
  fi
  build_tree=${snapshots[-1]}
  find_newer_filter=()
  echo "Collect-only mode: reusing existing build tree $build_tree"
elif git -C "$kernel_tree" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Exporting clean source snapshot for build..."
  repo_ref=$(git -C "$kernel_tree" symbolic-ref --short -q HEAD || true)
  if [[ -z "$repo_ref" ]]; then
    repo_ref=$(git -C "$kernel_tree" describe --tags --exact-match 2>/dev/null || true)
  fi
  if [[ -z "$repo_ref" ]]; then
    repo_ref=$(git -C "$kernel_tree" rev-parse --short HEAD)
  fi
  local_stamp=""
  if [[ -f "$localversion_file" ]]; then
    local_stamp=$(tr -d '[:space:]' < "$localversion_file" || true)
    local_stamp=${local_stamp#-}
  fi
  if [[ -z "$local_stamp" ]]; then
    local_stamp="$(date +%Y%m%d)01"
  fi
  safe_ref=$(printf '%s' "$repo_ref" | tr $'/ \t\r\n' '-' | tr -cd '[:alnum:]._-')
  safe_stamp=$(printf '%s' "$local_stamp" | tr $'/ \t\r\n' '-' | tr -cd '[:alnum:]._-')
  clean_src_dir="$build_workspace/linux-src-${safe_ref}-${safe_stamp}"
  rm -rf "$clean_src_dir"
  mkdir -p "$clean_src_dir"
  git -C "$kernel_tree" archive --format=tar HEAD | tar -xf - -C "$clean_src_dir"
  echo "Cleaning exported snapshot..."
  make -C "$clean_src_dir" mrproper >/dev/null 2>&1
  cp "$kernel_tree/.config" "$clean_src_dir/.config"
  if [[ -f "$localversion_file" ]]; then
    cp "$localversion_file" "$clean_src_dir/localversion.wsl-build"
  fi
   if grep -q "krel_pkg=.*tr '\\[:upper:\\]' '\\[:lower:\\]'" "$clean_src_dir/scripts/package/mkdebian"; then
     :
   else
     patch -d "$clean_src_dir" -p1 --forward --batch --silent < "$patch_file"
   fi
   cleanup_snapshot=1
   build_tree="$clean_src_dir"
fi

echo "Running olddefconfig..."
if [[ $collect_only -eq 0 ]]; then
  make -C "$build_tree" olddefconfig
fi

echo "Cleaning stale debian/ directory..."
rm -rf "$build_tree/debian"
echo "Building and packaging (bindeb-pkg)..."
if [[ $collect_only -eq 0 ]]; then
  make -C "$build_tree" -j"$jobs" bindeb-pkg
fi

kernelrelease=$(make -s -C "$build_tree" kernelrelease)
image_relpath=$(make -s -C "$build_tree" image_name)
image_path="$build_tree/$(dirname "$image_relpath")/$(basename "$image_relpath")"

if [[ ! -f "$image_path" ]]; then
  echo "Kernel image not found at expected path: $image_path" >&2
  exit 1
fi

stamp="$kernelrelease"
if [[ -f "$localversion_file" ]]; then
  localvalue=$(tr -d '[:space:]' < "$localversion_file" || true)
  localvalue=${localvalue#-}
  if [[ -n "$localvalue" ]]; then
    stamp="$localvalue"
  fi
fi

out_dir="$output_root/$stamp"
mkdir -p "$out_dir"

echo "Staging modules (no recompilation)..."
rm -rf "$modules_stage/lib/modules/$kernelrelease"
make -C "$build_tree" modules_install INSTALL_MOD_PATH="$modules_stage" INSTALL_MOD_STRIP=1

vhdx_out="$out_dir/modules.vhdx"
if [[ $skip_vhdx -eq 0 ]]; then
  if [[ -e "$vhdx_out" ]]; then
    rm -f "$vhdx_out"
  fi

  echo "Creating modules VHDX..."
  if [[ ${EUID} -eq 0 ]]; then
    "$helper_script" "$modules_stage" "$kernelrelease" "$vhdx_out"
  else
    if ! sudo -n true >/dev/null 2>&1; then
      echo "sudo privileges are required to create modules.vhdx." >&2
      echo "Run: sudo -v  # then rerun this script" >&2
      exit 1
    fi
    sudo "$helper_script" "$modules_stage" "$kernelrelease" "$vhdx_out"
  fi
else
  echo "Skipping modules VHDX (--no-vhdx)."
fi

cp "$image_path" "$out_dir/vmlinuz-$kernelrelease"

mapfile -t image_debs < <(find "$build_workspace" "$(dirname "$kernel_tree")" "$(dirname "$build_tree")" -maxdepth 4 -type f -name "linux-image-*.deb" ! -name "*-dbg_*.deb" "${find_newer_filter[@]}" 2>/dev/null | sort -u)
mapfile -t header_debs < <(find "$build_workspace" "$(dirname "$kernel_tree")" "$(dirname "$build_tree")" -maxdepth 4 -type f -name "linux-headers-*.deb" "${find_newer_filter[@]}" 2>/dev/null | sort -u)

if [[ ${#image_debs[@]} -eq 0 || ${#header_debs[@]} -eq 0 ]]; then
  echo "Unable to find newly built linux-image/linux-headers .deb files." >&2
  echo "Searched under: $(dirname "$kernel_tree")" >&2
  exit 1
fi

image_deb=${image_debs[-1]}
header_deb=${header_debs[-1]}
rm -f "$out_dir"/linux-image-*.deb "$out_dir"/linux-headers-*.deb
cp "$image_deb" "$header_deb" "$out_dir/"

echo
echo "Artifacts collected in: $out_dir"
echo "  $(basename "$image_deb")"
echo "  $(basename "$header_deb")"
if [[ $skip_vhdx -eq 0 ]]; then
  echo "  modules.vhdx"
fi
echo "  vmlinuz-$kernelrelease"
