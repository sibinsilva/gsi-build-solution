#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# setup_tree.sh — Install Treble GSI local manifest & sync required repositories
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTION_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="${1:-/data/build}"

if [ ! -d "$SOURCE_DIR/.repo" ]; then
    echo "[ERROR] Android repo root not found at: $SOURCE_DIR"
    echo "Usage: $0 [/path/to/android/source]"
    exit 1
fi

echo "==> [1/3] Installing treble.xml into $SOURCE_DIR/.repo/local_manifests/treble.xml"
mkdir -p "$SOURCE_DIR/.repo/local_manifests"
rm -f "$SOURCE_DIR/.repo/local_manifests/remove_duplicate.xml"
cp -f "$SOLUTION_ROOT/manifests/treble.xml" "$SOURCE_DIR/.repo/local_manifests/treble.xml"

echo "==> [2/3] Syncing Treble, VNDK (v28/v29/v30), Magisk (android-10.0), and QcRilAm repositories"
cd "$SOURCE_DIR"
repo sync -c --no-tags --force-sync -j8 \
    device/phh/treble \
    device/asus/I005D \
    vendor/asus/camera \
    vendor/hardware_overlay \
    treble_app \
    vendor/vndk-tests \
    vendor/interfaces \
    vendor/lptools \
    vendor/magisk \
    packages/apps/QcRilAm \
    prebuilts/vndk/v28 \
    prebuilts/vndk/v29 \
    prebuilts/vndk/v30

echo "==> [3/3] Ensuring clean state in device/phh/treble, device/asus/I005D, treble_app, and vendor/interfaces"
git -C "$SOURCE_DIR/device/phh/treble" checkout -f
git -C "$SOURCE_DIR/device/phh/treble" clean -fd
git -C "$SOURCE_DIR/device/asus/I005D" checkout -f
git -C "$SOURCE_DIR/device/asus/I005D" clean -fd
git -C "$SOURCE_DIR/treble_app" checkout -f
git -C "$SOURCE_DIR/treble_app" clean -fd
git -C "$SOURCE_DIR/vendor/interfaces" checkout -f
git -C "$SOURCE_DIR/vendor/interfaces" clean -fd

echo "==> [OK] Tree setup complete."
