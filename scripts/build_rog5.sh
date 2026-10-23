#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# build_rog5.sh — End-to-End Builder for the ASUS ROG Phone 5/5s (I005D)
#                 Android 16 (bp4a) stock-vendor system image
# ==============================================================================
# Usage:
#   ./scripts/build_rog5.sh [/path/to/source] [userdebug|user] [/path/to/release]
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${1:-/data/build}"
BUILD_VARIANT="${2:-userdebug}"
RELEASE_DIR="${3:-/data/release}"
JOBS="${JOBS:-$(nproc)}"

LUNCH_TARGET="lunaris_I005D-bp4a-${BUILD_VARIANT}"

echo "=================================================================="
echo "  ASUS ROG Phone 5/5s (I005D) Stock-Vendor System Image Build"
echo "  Source Dir    : $SOURCE_DIR"
echo "  Target Lunch  : $LUNCH_TARGET"
echo "  Release Dir   : $RELEASE_DIR"
echo "  Parallel Jobs : $JOBS"
echo "=================================================================="

# 1. Setup manifest & sync Treble + I005D repos
"$SCRIPT_DIR/setup_tree.sh" "$SOURCE_DIR"

# 2. Apply TrebleDroid & Personal patches idempotently
"$SCRIPT_DIR/apply_patches.sh" "$SOURCE_DIR"

# 3. Pre-build source verification
"$SCRIPT_DIR/verify_gsi.sh" --tree "$SOURCE_DIR"

# 4. Run the Android build (installclean drops stale product output, keeps intermediates)
cd "$SOURCE_DIR"
export USE_CCACHE=1
export CCACHE_DIR="${CCACHE_DIR:-/data/ccache}"

set +u
source build/envsetup.sh
lunch "$LUNCH_TARGET"
m installclean
m systemimage -j"$JOBS"
BUILT_IMG="$(get_build_var PRODUCT_OUT)/system.img"
set -u

case "$BUILT_IMG" in
    /*) ;;
    *) BUILT_IMG="$SOURCE_DIR/$BUILT_IMG" ;;
esac

# 5. Post-build image verification (generic GSI checks + ROG5 specifics)
"$SCRIPT_DIR/verify_gsi.sh" --rog5 "$SOURCE_DIR" "$BUILT_IMG"

# 6. Copy & compress into RELEASE_DIR
mkdir -p "$RELEASE_DIR"
DATE_STAMP="$(date -u +%Y%m%d)"
OUT_NAME="ROG5_I005D-stockvendor-GAPPS-${BUILD_VARIANT}-${DATE_STAMP}.img"

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
