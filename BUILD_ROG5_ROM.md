# ASUS ROG Phone 5 / 5s (anakin / I005D) Stock-Vendor Custom ROM Guide

## 1. Overview

This document describes how to build, verify, and install the **Android 16 QPR2 (`bp4a`) Stock-Vendor Custom ROM** for the **ASUS ROG Phone 5 / 5s** (`anakin` / `I005D` / `ASUS_I005_1` / `ASUS_I005DA`).

Unlike generic GSIs that must accommodate hundreds of OEM devices, this build target is specifically tuned for ASUS ROG Phone 5 hardware while retaining 100% compatibility with the unmodified ASUS stock vendor (`/vendor`) and ODM (`/odm`) partitions.

---

## 2. Hardware Architecture & Key Fixes

### A. Goodix Optical Under-Display Fingerprint (UDFPS @2.3 HIDL)
- **Vendor Daemon Preservation:** In `/system/bin/rw-system.sh`, do **not** bind-mount an empty file over `/vendor/bin/hw/android.hardware.biometrics.fingerprint@2.1-service`. On ROG 5, that vendor binary is what publishes `vendor.goodix.hardware.biometrics.fingerprint@2.1::IGoodixFingerprintDaemon`.
- **Deadlock Avoidance:** The system-side adapter HAL (`device/phh/treble/hal/anakin-fp/BiometricsFingerprint.cpp`) calls `IGoodixFingerprintDaemon::tryGetService()` (non-blocking) instead of `getService()`.
- **Null Safety:** In `BiometricsFingerprint.cpp`, all legacy `mDevice` calls (including `setActiveGroup`) are guarded against null pointers, preventing crashes during fingerprint enrollment.
- **Coordinate Bridging:** UDFPS touch events are mapped to 16.16 coordinate format and routed directly to `/data/vendor/fp_xy` with high-brightness mode (HBM) triggering.

### B. ASUS ROG 5 Hardware Features (`TrebleApp.apk`)
- **Aura Sync RGB:** Controls the back-cover RGB ROG logo (static, breathing, strobing, color cycle) and lighting triggers.
- **AirTriggers:** Ultrasonic shoulder buttons sensitivity, vibration feedback, and tap/slide mapping.
- **Dual Wi-Fi:** HyperFusion simultaneous 2.4 GHz + 5 GHz Wi-Fi acceleration.
- **Bypass Charging:** Direct motherboard power delivery during gaming sessions to prevent battery degradation and heating.
- **Game Mode Boost:** Qualcomm CPU/GPU scheduler boost integration.

### C. Display, Touch & Audio
- **144 Hz Display:** 60 / 90 / 120 / 144 Hz peak and minimum refresh rate selectors enabled via framework overlays.
- **440 DPI:** Native LCD density set via `ro.sf.lcd_density=440`.
- **Touch IC Fixup:** `fts_game_mode` node permissions applied on `sys.boot_completed=1` via `device/phh/treble/rog5-fixups.rc`.
- **Bluetooth & USB Audio:** System-side `audio.sysbta.default` and sysbta policy configuration.

---

## 3. Device Tree Structure

The device tree is located at [`device/asus/I005D`](file:///data/build/device/asus/I005D) and is versioned in
[`sibinsilva/device_asus_I005D_GSI`](https://github.com/sibinsilva/device_asus_I005D_GSI) (`android-16.0`).
It is synced by `manifests/treble.xml` and reset to a clean state by `scripts/setup_tree.sh`, so every change
must be committed and pushed there before building.

```text
device/asus/I005D/
├── AndroidProducts.mk    # Product makefile registration and lunch choices
├── BoardConfig.mk        # Board configuration & dynamic partition sizing
├── lunaris_I005D.mk      # Main product makefile (model, brand, GMS flags)
├── device.mk             # Packages, permissions, scripts, overlays
├── system.prop           # Market name and lunaris device properties
├── files/
│   └── rw-system.sh      # Runtime boot initialization script
└── overlay/              # ROG 5 specific framework & Settings overrides
    ├── frameworks/base/core/res/res/values/config.xml
    ├── frameworks/base/packages/SystemUI/res/values/config.xml
    └── packages/apps/Settings/res/values/
```

> [!IMPORTANT]
> **Android 16 Soong Requirement:** Do not use legacy `PRODUCT_BUILD_PROP_OVERRIDES += TARGET_DEVICE=...` syntax in `lunaris_I005D.mk`. Define properties natively via `PRODUCT_SYSTEM_DEVICE := ASUS_I005_1`, `PRODUCT_SYSTEM_MODEL := ASUS_I005DA`, and `PRODUCT_SYSTEM_NAME := WW_I005D`.

---

## 4. Build Instructions

### Automated (recommended)
```bash
/data/gsi-build-solution/scripts/build_rog5.sh /data/build userdebug /data/release
```
This syncs the tree, applies patches, verifies the source, runs `m installclean` + `m systemimage`,
verifies the image with `verify_gsi.sh --rog5`, and writes `ROG5_I005D-stockvendor-GAPPS-<variant>-<date>.img(.xz)`
plus SHA-256 files to the release directory.

### Manual
### Step 1: Environment Setup
```bash
cd /data/build
source build/envsetup.sh
```

### Step 2: Lunch Target
```bash
lunch lunaris_I005D-bp4a-userdebug
```

### Step 3: Compile System Image
```bash
m installclean
m systemimage -j$(nproc)
```

The output image will be generated at:
```text
out/target/product/I005D/system.img
```

---

## 5. Image Verification

Before releasing or flashing, verify the output image using the unprivileged `debugfs` tool and verification script:

```bash
# Verify the built image against all required VNDK, SELinux, and binary rules
/data/gsi-build-solution/scripts/verify_gsi.sh --rog5 /data/build /data/build/out/target/product/I005D/system.img

# Note: Android 16 Soong writes ro.product.system.name from the device name (ASUS_I005_1),
# so PRODUCT_SYSTEM_NAME (WW_I005D) does not appear there.

# Inspect build properties inside the image
/usr/sbin/debugfs -R "cat system/build.prop" out/target/product/I005D/system.img | grep -E "ro.product|ro.lunaris"

# Inspect anakin UDFPS binary
/usr/sbin/debugfs -R "stat system/bin/hw/android.hardware.biometrics.fingerprint@2.3-service.anakin" out/target/product/I005D/system.img
```

---

## 6. Installation Methods

### Option A: Booting via DSU (Dynamic System Updates — Safe Dual-Boot)

1. Decompress the `.xz` archive:
   ```bash
   xz -d -v ROG5_I005D-stockvendor-GAPPS-userdebug-20261023.img.xz
   ```
2. Push the image to device storage and start DSU installation:
   ```bash
   adb push ROG5_I005D-stockvendor-GAPPS-userdebug-20261023.img /sdcard/
   adb shell am start-activity \
       -n com.android.dynsystem/com.android.dynsystem.VerificationActivity \
       -a android.os.image.action.START_INSTALL \
       -d file:///sdcard/ROG5_I005D-stockvendor-GAPPS-userdebug-20261023.img \
       --el KEY_USERDATA_SIZE 17179869184
   ```
3. Tap **Restart** from the Android system notification once installation is finished.

### Option B: Flashing via `fastbootd`

1. Reboot device into `fastbootd`:
   ```bash
   adb reboot fastboot
   ```
2. Flash the system partition:
   ```bash
   fastboot flash system ROG5_I005D-stockvendor-GAPPS-userdebug-20261023.img
   ```
3. *(Optional for first install)* Erase userdata:
   ```bash
   fastboot erase userdata
   ```
4. Reboot into Android:
   ```bash
   fastboot reboot
   ```
