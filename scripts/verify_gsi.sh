#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# verify_gsi.sh — Pre-build source verification & Post-build system.img check
# ==============================================================================

MODE="${1:---all}"
SOURCE_DIR="${2:-/data/build}"
IMAGE_PATH="${3:-$SOURCE_DIR/out/target/product/tdgsi_arm64_ab/system.img}"

verify_tree() {
    echo "==> Verifying Android GSI source tree at: $SOURCE_DIR"
    local failed=0

    check_file() {
        if [ ! -e "$SOURCE_DIR/$1" ]; then
            echo "  [FAIL] Missing required file/dir: $1"
            failed=1
        else
            echo "  [OK]   Found $1"
        fi
    }

    check_grep() {
        if ! grep -q "$2" "$SOURCE_DIR/$1" 2>/dev/null; then
            echo "  [FAIL] Missing '$2' in $1"
            failed=1
        else
            echo "  [OK]   Verified '$2' in $1"
        fi
    }

    check_file "device/phh/treble/AndroidProducts.mk"
    check_grep "build/make/target/product/gsi/Android.bp" "com.android.vndk.v29"
    check_grep "build/make/target/product/gsi/Android.bp" "com.android.vndk.v30"
    check_grep "packages/modules/vndk/apex/Android.bp" "com.android.vndk.v28"
    check_grep "vendor/magisk/Android.bp" "resetprop_phh"
    check_file "packages/apps/QcRilAm/Android.bp"
    check_file "prebuilts/vndk/v28/arm64/Android.bp"
    check_file "prebuilts/vndk/v29/arm64/Android.bp"
    check_file "prebuilts/vndk/v30/arm64/Android.bp"
    check_file "vendor/interfaces/vendor/lge/hardware/vibrator/1.0/Android.bp"

    local orig_count
    orig_count="$(find "$SOURCE_DIR/frameworks" "$SOURCE_DIR/packages" "$SOURCE_DIR/system" -name "*.orig" 2>/dev/null | wc -l)"
    if [ "$orig_count" -gt 0 ]; then
        echo "  [FAIL] Found $orig_count stray .orig files that will break AAPT2"
        failed=1
    else
        echo "  [OK]   Zero stray .orig files in frameworks/packages/system"
    fi

    if [ "$failed" -ne 0 ]; then
        echo "[ERROR] Source tree verification FAILED."
        return 1
    fi
    echo "==> [PASS] Source tree verification succeeded!"
}

verify_image() {
    echo "==> Verifying built system.img via debugfs: $IMAGE_PATH"
    if [ ! -f "$IMAGE_PATH" ]; then
        echo "[ERROR] Image file not found: $IMAGE_PATH"
        return 1
    fi

    local failed=0
    local required_paths=(
        "/system/bin/init"
        "/system/bin/resetprop_phh"
        "/system/bin/rw-system.sh"
        "/system/bin/phh-on-boot.sh"
        "/system/bin/phh-prop-handler.sh"
        "/system/etc/init/vndk.rc"
        "/system/system_ext/apex/com.android.vndk.v28.apex"
        "/system/system_ext/apex/com.android.vndk.v29.apex"
        "/system/system_ext/apex/com.android.vndk.v30.apex"
        "/system/system_ext/apex/com.android.vndk.v31.apex"
        "/system/system_ext/apex/com.android.vndk.v32.apex"
        "/system/system_ext/apex/com.android.vndk.v33.apex"
        "/system/system_ext/apex/com.android.vndk.v34.apex"
        "/system/lib64/vndk-28"
        "/system/lib64/vndk-29"
        "/system/app/QcRilAm/QcRilAm.apk"
        "/system/priv-app/TrebleApp/TrebleApp.apk"
    )

    for p in "${required_paths[@]}"; do
        if /usr/sbin/debugfs -R "stat $p" "$IMAGE_PATH" 2>/dev/null | grep -q "Inode:"; then
            echo "  [OK]   Present in image: $p"
        else
            echo "  [FAIL] MISSING in image: $p"
            failed=1
        fi
    done

    if [ "$failed" -ne 0 ]; then
        echo "[ERROR] Image verification FAILED."
        return 1
    fi
    echo "==> [PASS] system.img verification succeeded!"
}

verify_rog5_image() {
    echo "==> Verifying ROG Phone 5/5s (I005D) specifics in: $IMAGE_PATH"
    local failed=0
    local required_paths=(
        "/system/bin/hw/android.hardware.biometrics.fingerprint@2.3-service.anakin"
        "/system/etc/init/android.hardware.biometrics.fingerprint@2.3-service.anakin.rc"
        "/system/etc/permissions/android.hardware.fingerprint.xml"
    )

    for p in "${required_paths[@]}"; do
        if /usr/sbin/debugfs -R "stat $p" "$IMAGE_PATH" 2>/dev/null | grep -q "Inode:"; then
            echo "  [OK]   Present in image: $p"
        else
            echo "  [FAIL] MISSING in image: $p"
            failed=1
        fi
    done

    local build_prop
    build_prop="$(/usr/sbin/debugfs -R "cat /system/build.prop" "$IMAGE_PATH" 2>/dev/null)"
    local required_props=(
        "ro.product.system.device=ASUS_I005_1"
        "ro.product.system.model=ASUS_I005DA"
    )
    for prop in "${required_props[@]}"; do
        if grep -qx "$prop" <<<"$build_prop"; then
            echo "  [OK]   build.prop: $prop"
        else
            echo "  [FAIL] build.prop missing: $prop"
            failed=1
        fi
    done

    if [ "$failed" -ne 0 ]; then
        echo "[ERROR] ROG5 image verification FAILED."
        return 1
    fi
    echo "==> [PASS] ROG5 image verification succeeded!"
}

case "$MODE" in
    --tree)
        verify_tree
        ;;
    --image)
        verify_image
        ;;
    --rog5)
        verify_image
        verify_rog5_image
        ;;
    --all|*)
        verify_tree
        if [ -f "$IMAGE_PATH" ]; then
            verify_image
        fi
        ;;
esac
