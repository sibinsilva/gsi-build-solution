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
#   5. Fails (exit 1) if any patch cannot be applied, unless it is listed in
#      patches/KNOWN_UNAPPLIED.txt.
#   6. --check reports every patch's status without modifying the tree.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTION_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CHECK_ONLY=0
if [ "${1:-}" = "--check" ]; then
    CHECK_ONLY=1
    shift
fi
SOURCE_DIR="${1:-/data/build}"

if [ ! -d "$SOURCE_DIR/build/make" ]; then
    echo "[ERROR] Invalid Android build tree: $SOURCE_DIR"
    echo "Usage: $0 [--check] [/path/to/android/source]"
    exit 1
fi

TREBLEDROID_DIR="$SOLUTION_ROOT/patches/trebledroid"
PERSONAL_DIR="$SOLUTION_ROOT/patches/personal"
KNOWN_UNAPPLIED_FILE="$SOLUTION_ROOT/patches/KNOWN_UNAPPLIED.txt"

FAILED_PATCHES=()
KNOWN_SKIPPED=()

# A patch whose lines were later changed by another patch no longer reverses
# cleanly; treat it as applied if a commit with its subject (or the
# "Apply <file>" commit this script makes) is in the repo's recent history.
# Called with the repo's recent commit subjects in $REPO_SUBJECTS (set once per
# repo, so no pipe into grep -q that would SIGPIPE under pipefail).
applied_by_subject() {
    local patch_file="$1" patch_name="$2" subject
    subject="$(sed -n 's/^Subject: \(\[PATCH[^]]*\] \)\{0,1\}//p' "$patch_file" | head -1)"
    command grep -xF -e "$subject" -e "Apply $patch_name" -e "Apply $patch_name (with fuzz)" \
        <<<"$REPO_SUBJECTS" >/dev/null
}

# Patch paths (relative to patches/) that are expected not to apply, one per
# line; '#' starts a comment.
declare -A KNOWN_UNAPPLIED=()
if [ -f "$KNOWN_UNAPPLIED_FILE" ]; then
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        [ -n "$line" ] && KNOWN_UNAPPLIED["$line"]=1
    done < "$KNOWN_UNAPPLIED_FILE"
fi

is_known_unapplied() {
    [ -n "${KNOWN_UNAPPLIED["$1"]+set}" ]
}

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

    local category_rel
    category_rel="$(basename "$category_dir")"

    echo ""
    echo "=================================================================="
    if [ "$CHECK_ONLY" -eq 1 ]; then
        echo "  CHECKING ${category_name} PATCHES"
    else
        echo "  APPLYING ${category_name} PATCHES"
    fi
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
        REPO_SUBJECTS="$(git log --format=%s -n 2000 2>/dev/null || true)"

        for patch_file in "$category_dir/$path_entry"/*.patch; do
            [ -f "$patch_file" ] || continue
            local patch_name patch_rel
            patch_name="$(basename "$patch_file")"
            patch_rel="$category_rel/$path_entry/$patch_name"

            # 1. Check if already applied (reverse dry-run succeeds)
            if patch -f -p1 --dry-run -R < "$patch_file" >/dev/null 2>&1; then
                echo "  [ALREADY APPLIED] $patch_name"
                continue
            fi
            if applied_by_subject "$patch_file" "$patch_name"; then
                echo "  [ALREADY APPLIED (by subject)] $patch_name"
                continue
            fi

            if [ "$CHECK_ONLY" -eq 1 ]; then
                if git apply --check "$patch_file" 2>/dev/null ||
                        patch -f -p1 --no-backup-if-mismatch --dry-run < "$patch_file" >/dev/null 2>&1; then
                    echo "  [WOULD APPLY] $patch_name"
                elif is_known_unapplied "$patch_rel"; then
                    echo "  [KNOWN UNAPPLIED] $patch_name"
                    KNOWN_SKIPPED+=("$patch_rel")
                else
                    echo "  [FAIL] $patch_name does not apply"
                    FAILED_PATCHES+=("$patch_rel")
                fi
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
            elif is_known_unapplied "$patch_rel"; then
                echo "  [KNOWN UNAPPLIED] $patch_name"
                KNOWN_SKIPPED+=("$patch_rel")
            else
                echo "  [FAIL] Could not apply $patch_name — check $tree manually"
                FAILED_PATCHES+=("$patch_rel")
            fi
        done

        popd >/dev/null
    done
}

apply_category "TREBLEDROID" "$TREBLEDROID_DIR"
apply_category "PERSONAL" "$PERSONAL_DIR"

if [ "$CHECK_ONLY" -eq 0 ]; then
    echo ""
    echo "==> Cleaning up any stray .orig / .rej files across frameworks, packages, and system..."
    find "$SOURCE_DIR/frameworks" "$SOURCE_DIR/packages" "$SOURCE_DIR/system" \
        \( -name "*.orig" -o -name "*.rej" \) -delete 2>/dev/null || true
fi

echo ""
if [ "${#KNOWN_SKIPPED[@]}" -gt 0 ]; then
    echo "==> Known unapplied (patches/KNOWN_UNAPPLIED.txt):"
    printf '      %s\n' "${KNOWN_SKIPPED[@]}"
fi
if [ "${#FAILED_PATCHES[@]}" -gt 0 ]; then
    echo "==> [ERROR] ${#FAILED_PATCHES[@]} patch(es) could not be applied:"
    printf '      %s\n' "${FAILED_PATCHES[@]}"
    echo "    Refresh them, or list them in patches/KNOWN_UNAPPLIED.txt with the reason."
    exit 1
fi
echo "==> [OK] All patches processed."
