#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# apply_patches.sh — Idempotently apply all TrebleDroid & Personal GSI patches
# ==============================================================================
# Features:
#   1. Properly cd's into $SOURCE_DIR before resolving repo subdirectories.
#   2. Maps platform_build_core, platform_build_target, platform_build_target_board
#      to build/make, and platform_vendor_pixel_gms / platform_vendor_gms to the
#      active GMS vendor directory.
#   3. Uses `patch --no-backup-if-mismatch` so zero `.orig` files are left behind
#      to break Android AAPT2 resource compilation.
#   4. Skips patches that are already applied (safe to re-run at any time).
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTION_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="${1:-/data/build}"

if [ ! -d "$SOURCE_DIR/build/make" ]; then
    echo "[ERROR] Invalid Android build tree: $SOURCE_DIR"
    echo "Usage: $0 [/path/to/android/source]"
    exit 1
fi

TREBLEDROID_DIR="$SOLUTION_ROOT/patches/trebledroid"
PERSONAL_DIR="$SOLUTION_ROOT/patches/personal"

map_patch_dir_to_tree() {
    local patch_dir="$1"
    local tree
    tree="$(tr '_' '/' <<<"$patch_dir" | sed -e 's;^platform/;;g')"

    case "$tree" in
        build|build/core|build/target|build/target/board)
            tree="build/make"
            ;;
        vendor/hardware/overlay)
            tree="vendor/hardware_overlay"
            ;;
        treble/app)
            tree="treble_app"
            ;;
        vendor/partner/gms)
            tree="vendor/partner_gms"
            ;;
        vendor/pixel/gms|vendor/gms)
            if [ -d "$SOURCE_DIR/vendor/pixel/gms" ]; then
                tree="vendor/pixel/gms"
            else
                tree="vendor/gms"
            fi
            ;;
        lineage-sdk)
            tree="lineage-sdk"
            ;;
    esac
    echo "$tree"
}

apply_category() {
    local category_name="$1"
    local category_dir="$2"

    echo ""
    echo "=================================================================="
    echo "  APPLYING ${category_name} PATCHES"
    echo "=================================================================="

    for path_entry in $(cd "$category_dir" && echo *); do
        [ -d "$category_dir/$path_entry" ] || continue
        local tree
        tree="$(map_patch_dir_to_tree "$path_entry")"
        local target_dir="$SOURCE_DIR/$tree"

        if [ ! -d "$target_dir" ]; then
            echo "[SKIP] Target directory not found: $tree (from $path_entry)"
            continue
        fi

        echo "--- [$path_entry -> $tree] ---"
        pushd "$target_dir" >/dev/null

        for patch_file in "$category_dir/$path_entry"/*.patch; do
            [ -f "$patch_file" ] || continue
            local patch_name
            patch_name="$(basename "$patch_file")"

            # 1. Check if already applied (reverse dry-run succeeds)
            if patch -f -p1 --dry-run -R < "$patch_file" >/dev/null 2>&1; then
                echo "  [ALREADY APPLIED] $patch_name"
                continue
            fi

            # 2. Try clean git am / git apply
            if git apply --check "$patch_file" 2>/dev/null; then
                if git am --keep-cr "$patch_file" >/dev/null 2>&1; then
                    echo "  [APPLIED (git am)] $patch_name"
                else
                    git am --abort >/dev/null 2>&1 || true
                    git apply "$patch_file"
                    git add -u
                    git commit -m "Apply $patch_name" >/dev/null 2>&1 || true
                    echo "  [APPLIED (git apply)] $patch_name"
                fi
            # 3. Fallback to patch with fuzz (and --no-backup-if-mismatch to prevent .orig files)
            elif patch -f -p1 --no-backup-if-mismatch --dry-run < "$patch_file" >/dev/null 2>&1; then
                patch -f -p1 --no-backup-if-mismatch < "$patch_file" >/dev/null
                git add -u
                git commit -m "Apply $patch_name (with fuzz)" >/dev/null 2>&1 || true
                echo "  [APPLIED (patch)] $patch_name"
            else
                echo "  [WARN] Could not apply $patch_name cleanly — check $tree manually"
            fi
        done

        popd >/dev/null
    done
}

apply_category "TREBLEDROID" "$TREBLEDROID_DIR"
apply_category "PERSONAL" "$PERSONAL_DIR"

echo ""
echo "==> Cleaning up any stray .orig / .rej files across frameworks, packages, and system..."
find "$SOURCE_DIR/frameworks" "$SOURCE_DIR/packages" "$SOURCE_DIR/system" \
    \( -name "*.orig" -o -name "*.rej" \) -delete 2>/dev/null || true

echo "==> [OK] All patches processed."
