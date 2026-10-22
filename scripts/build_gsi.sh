#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# build_gsi.sh — Generic End-to-End Automated Builder for Android 16 (bp4a) GSI
# ==============================================================================
# Usage:
#   ./scripts/build_gsi.sh [/path/to/source] [userdebug|user] [/path/to/release] [product_name]
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${1:-/data/build}"
BUILD_VARIANT="${2:-userdebug}"
RELEASE_DIR="${3:-/data/release}"
PRODUCT_TARGET="${4:-}"
JOBS="${JOBS:-$(nproc)}"

# Auto-detect the GSI product target from device/phh/treble/AndroidProducts.mk if not provided
if [ -z "$PRODUCT_TARGET" ]; then
    PRODUCT_TARGET="$(awk -F'/' '/LOCAL_DIR.*\.mk/ {gsub(/\.mk[[:space:]]*\\?$/, "", $NF); print $NF; exit}' "$SOURCE_DIR/device/phh/treble/AndroidProducts.mk" 2>/dev/null || echo "treble_arm64_bgN")"
fi

LUNCH_TARGET="${PRODUCT_TARGET}-bp4a-${BUILD_VARIANT}"

echo "=================================================================="
echo "  Android 16 (bp4a) Generic System Image (GSI) Automated Build"
echo "  Source Dir    : $SOURCE_DIR"
echo "  Target Lunch  : $LUNCH_TARGET"
echo "  Release Dir   : $RELEASE_DIR"
echo "  Parallel Jobs : $JOBS"
echo "=================================================================="

# 1. Setup manifest & sync Treble repos
"$SCRIPT_DIR/setup_tree.sh" "$SOURCE_DIR"

# 2. Apply TrebleDroid & Personal patches idempotently
"$SCRIPT_DIR/apply_patches.sh" "$SOURCE_DIR"

# 3. Pre-build source verification
"$SCRIPT_DIR/verify_gsi.sh" --tree "$SOURCE_DIR"

# 4. Run the Android build
cd "$SOURCE_DIR"
export USE_CCACHE=1
export CCACHE_DIR="${CCACHE_DIR:-/data/ccache}"

set +u
source build/envsetup.sh
lunch "$LUNCH_TARGET"
m systemimage -j"$JOBS"
set -u

BUILT_IMG="$SOURCE_DIR/out/target/product/tdgsi_arm64_ab/system.img"

# 5. Post-build image verification
"$SCRIPT_DIR/verify_gsi.sh" --image "$SOURCE_DIR" "$BUILT_IMG"

# 6. Copy & compress into RELEASE_DIR
mkdir -p "$RELEASE_DIR"
DATE_STAMP="$(date -u +%Y%m%d)"
OUT_NAME="GSI_treble_arm64-ab-GAPPS-${BUILD_VARIANT}-${DATE_STAMP}.img"

echo "==> Copying system.img to $RELEASE_DIR/$OUT_NAME"
cp -f "$BUILT_IMG" "$RELEASE_DIR/$OUT_NAME"

pushd "$RELEASE_DIR" >/dev/null
sha256sum "$OUT_NAME" > "${OUT_NAME}.sha256"
echo "==> Compressing $OUT_NAME with xz -T0..."
xz -T0 -k -f "$OUT_NAME"
sha256sum "${OUT_NAME}.xz" > "${OUT_NAME}.xz.sha256"
popd >/dev/null

echo "=================================================================="
echo "  BUILD & PACKAGING COMPLETE!"
echo "  Raw Image        : $RELEASE_DIR/$OUT_NAME"
echo "  Compressed Image : $RELEASE_DIR/${OUT_NAME}.xz"
cat "$RELEASE_DIR/${OUT_NAME}.sha256"
cat "$RELEASE_DIR/${OUT_NAME}.xz.sha256"
echo "=================================================================="
