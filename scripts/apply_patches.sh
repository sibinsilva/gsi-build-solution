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
#   3. Applies each repo's patches as one ordered series (NNNN-*.patch numbers run
#      across patches/trebledroid and patches/personal) with `git am` only: the
#      series is exported from the tested tree, so any patch that does not apply
#      cleanly stops that repo's series (no fuzz). See patches/INFINITY_PORT.md.
#   4. Skips patches that are already applied (safe to re-run at any time).
#   5. Skips patches listed in patches/KNOWN_UNAPPLIED.txt without trying them,
#      and fails (exit 1) if any other patch cannot be applied.
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
    # Subject lines may be folded over several lines (RFC 2822); unfold them and
    # squeeze whitespace, as git does for the commit subject.
    subject="$(awk '/^Subject: /{s=substr($0,10); f=1; next} f&&/^[ \t]/{s=s $0; next} f{exit} END{print s}' "$patch_file" |
        sed -e 's/^\[PATCH[^]]*\] //' -e 's/[[:space:]]\{1,\}/ /g' -e 's/^ //' -e 's/ $//')"
    # "Apply <file>" commits from earlier runs may use an older NNNN- number.
    local stem="${patch_name#[0-9][0-9][0-9][0-9]-}"
    command grep -xF -e "$subject" -e "Apply $patch_name" -e "Apply $patch_name (with fuzz)" \
        <<<"$(sed -e 's/[[:space:]]\{1,\}/ /g' <<<"$REPO_SUBJECTS")" >/dev/null ||
    command grep -xE -e "Apply [0-9]{4}-$(sed 's/[][\.*^$+?(){}|/]/\\&/g' <<<"$stem")( \(with fuzz\))?" \
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
            elif [ -d "$SOURCE_DIR/vendor/google/gms" ]; then
                tree="vendor/google/gms"
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

# Each repo's patches are applied as one ordered series. Patch files carry a
# per-repo sequence number (NNNN-*.patch) across patches/trebledroid and
# patches/personal, exported from the tested tree, so the series replays the
# exact commit order even where TrebleDroid and personal patches interleave.
apply_tree_series() {
    local tree="$1"; shift
    local target_dir="$SOURCE_DIR/$tree"

    if [ ! -d "$target_dir" ]; then
        echo "[SKIP] Target directory not found: $tree"
        return
    fi

    echo "--- [$tree] ---"
    pushd "$target_dir" >/dev/null
    REPO_SUBJECTS="$(git log --format=%s -n 2000 2>/dev/null || true)"

    local patch_file
    for patch_file in "$@"; do
        local patch_name patch_rel
        patch_name="$(basename "$patch_file")"
        patch_rel="${patch_file#"$SOLUTION_ROOT/patches/"}"

        # 1. Check if already applied (reverse dry-run succeeds)
        if patch -f -p1 --dry-run -R < "$patch_file" >/dev/null 2>&1; then
            echo "  [ALREADY APPLIED] $patch_rel"
            continue
        fi
        if applied_by_subject "$patch_file" "$patch_name"; then
            echo "  [ALREADY APPLIED (by subject)] $patch_rel"
            continue
        fi
        # Listed patches are never attempted: a patch that only applies with
        # fuzz would otherwise change the tree from the tested state.
        if is_known_unapplied "$patch_rel"; then
            echo "  [KNOWN UNAPPLIED] $patch_rel"
            KNOWN_SKIPPED+=("$patch_rel")
            continue
        fi

        if [ "$CHECK_ONLY" -eq 1 ]; then
            # Later patches in a series can depend on earlier ones, so --check
            # only reports what applies against the current tree.
            if git apply --check "$patch_file" 2>/dev/null; then
                echo "  [WOULD APPLY] $patch_rel"
            else
                echo "  [FAIL] $patch_rel does not apply (may depend on an earlier patch in the series)"
                FAILED_PATCHES+=("$patch_rel")
            fi
            continue
        fi

        # 2. The series is exported from the tested tree, so it must apply cleanly.
        if git am --keep-cr "$patch_file" >/dev/null 2>&1; then
            echo "  [APPLIED] $patch_rel"
        else
            git am --abort >/dev/null 2>&1 || true
            echo "  [FAIL] Could not apply $patch_rel cleanly — upstream $tree moved; refresh the series"
            FAILED_PATCHES+=("$patch_rel")
            break
        fi
    done

    popd >/dev/null
}

echo ""
echo "=================================================================="
if [ "$CHECK_ONLY" -eq 1 ]; then
    echo "  CHECKING PATCH SERIES"
else
    echo "  APPLYING PATCH SERIES"
fi
echo "=================================================================="

declare -A TREE_PATCHES=()
for category_dir in "$TREBLEDROID_DIR" "$PERSONAL_DIR"; do
    for path_entry in $(cd "$category_dir" && echo *); do
        [ -d "$category_dir/$path_entry" ] || continue
        tree="$(map_patch_dir_to_tree "$path_entry")"
        for patch_file in "$category_dir/$path_entry"/*.patch; do
            [ -f "$patch_file" ] || continue
            TREE_PATCHES["$tree"]+="$(basename "$patch_file")"$'\t'"$patch_file"$'\n'
        done
    done
done

for tree in $(printf '%s\n' "${!TREE_PATCHES[@]}" | sort); do
    mapfile -t series < <(printf '%s' "${TREE_PATCHES[$tree]}" | sort -t$'\t' -k1,1 | cut -f2)
    apply_tree_series "$tree" "${series[@]}"
done

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
