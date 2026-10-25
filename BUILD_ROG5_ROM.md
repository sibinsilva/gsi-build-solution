# ASUS ROG Phone 5 / 5s (anakin / I005D) Stock-Vendor Custom ROM Guide

## 1. Overview

This document describes how to build, verify, and install the **Android 16 QPR2 (`bp4a`) Stock-Vendor Custom ROM** for the **ASUS ROG Phone 5 / 5s** (`anakin` / `I005D` / `ASUS_I005_1` / `ASUS_I005DA`).

Unlike generic GSIs that must accommodate hundreds of OEM devices, this build target is specifically tuned for ASUS ROG Phone 5 hardware while retaining 100% compatibility with the unmodified ASUS stock vendor (`/vendor`) and ODM (`/odm`) partitions.

---

## 2. Hardware Architecture & Key Fixes

### A. Goodix Optical Under-Display Fingerprint (UDFPS @2.3 HIDL)
The stock vendor `@2.1-service` owns the Goodix sensor, TEE app and `IGoodixFingerprintDaemon`; the
system-side `anakin` HAL (`device/phh/treble/hal/anakin-fp`) adds the UDFPS 2.3 interface on top of it.
Every link below is required — each one was a separate cause of enrollment failing:

- **VINTF:** `device/asus/I005D/framework_manifest.xml` declares only `IBiometricsFingerprint@2.3/default`
  (wired via `DEVICE_FRAMEWORK_MANIFEST_FILE` in `BoardConfig.mk`). libhidl refuses to register a version that
  isn't in a manifest; 2.3 also covers 2.1/2.2 lookups. Never list 2.1 and 2.3 for the same instance — libvintf
  rejects it ("Conflicting FqInstance" / "Duplicated major version") and the device fails to boot. Validate any
  manifest change with `checkvintf` against the phone's vendor VINTF files before flashing.
- **Vendor daemon kept alive:** `rw-system.sh` must not bind-mount over `/vendor/bin/hw/android.hardware.biometrics.fingerprint@2.1-service`.
- **Registration order:** `anakin` waits for the Goodix daemon and the vendor `IBiometricsFingerprint@2.1` before
  registering, so it registers last (hwservicemanager keeps the last registrant of `default`).
- **Forwarding:** `libgf_hal` can't be loaded a second time in `anakin`, so the 2.1 calls (enroll, authenticate, …)
  are forwarded to the vendor service; `anakin` drives UDFPS through daemon commands 200001/200002/200003.
- **Illumination kept on:** `anakin` drops the HAL's `ACQUIRED_VENDOR` callbacks (as stock does); SystemUI would
  otherwise remove the UDFPS illumination before capture (`GF_ERROR_ACQUIRED_IMAGER_DIRTY`).
- **FOD spot layer:** `patches/personal/platform_frameworks_native/0013-FOD-support-for-Asus.patch` tags the
  UdfpsControllerOverlay layers with Asus layer classes 4/5 (`persist.sys.phh.fod.asus=true`, set by `rw-system.sh`),
  so the Asus HWC flags the spot and the kernel runs its frame-synced FOD HBM.
- **HBM property:** `patches/personal/platform_device_phh_treble/0001-*.patch` lets `anakin` set
  `sys.phh.oplus.fppress`, handled by `phh-prop-handler.sh` (`/proc/globalHbm`, `fod_touched`, `/proc/driver/fp_xy`).

- **Screen-off / AOD one-touch unlock:** while `vendor.asus.touch_control_fod` is set, the touch driver reports a
  finger on the sensor as `KEY_F` instead of a touch and filters that finger until it lifts.
  - `patches/personal/platform_frameworks_base/0035-*`: SystemUI arms it on screen off (UDFPS enrolled) via
    `sys.phh.oplus.fppress.fodctrl`; on a `WAKE_KEY` wake it starts the scan through `onAodInterrupt`, and any
    other wake disarms it immediately (otherwise on-screen touches over the sensor are swallowed).
  - `patches/personal/platform_device_phh_treble/0002-*`: `rog5-fixups.rc` sets `persist.vendor.asus.fp.wakeup=true`
    and mirrors `fodctrl` into `vendor.asus.touch_control_fod` (ASUS `init.asus.rc` writes both to the touch driver).
  - `device/asus/I005D/keylayout/fts_ts.kl`: `Generic.kl` with `KEY_F` (33) → `WAKEUP` and `KEY_U`/`KEY_O`/`KEY_L`
    unmapped so finger-up never types letters.

### A2. ASUS stock Camera (`com.asus.camera`)
The stock ASUS Camera (8.21.8.0.230327, from firmware WW-33.0210.0210.200) ships as a presigned privileged app.
- **App:** private repo `sibinsilva/vendor_asus_I005D_camera` → `vendor/asus/camera` (proprietary APK; keep the repo
  private; `repo sync` needs GitHub auth for it). Installed by `device.mk` (`PRODUCT_PACKAGES += AsusCamera`).
- **The gate:** the ASUS camx CHI override (`ExtensionModule::GetNumCameras`) caps the camera count at 4 unless
  `vendor.camera.asus.system=1`. Stock sets it in `/system/build.prop`, together with ASUS Camera's per-lens config;
  `device/asus/I005D/system.prop` carries that block verbatim. `vendor.camera.*` is labelled `vendor_asus_camera_prop`,
  so `getprop` from the shell shows nothing; check `dumpsys media.camera` instead (7 devices, like stock).
- **Aux cameras:** the framework hides camera IDs ≥ 2 from apps not in `vendor.camera.aux.packagelist`;
  `patches/personal/platform_device_phh_treble/0003-*` sets it to stock's list plus `com.asus.camera`.
- **Kept from the investigation (tested, maybe not required):** `ro.vendor.qti.va_aosp/va_odm.support=1` with their
  QSSI SELinux labels (`0004-*`), `ro.hardware.chipname/cpuinfo`, and `ro.build.product=ZS673KS` in `rw-system.sh`.

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

DSU's `file://` installer rejects a raw `.img` (`UnsupportedFormatException`) and needs the
uncompressed system size passed explicitly; without `KEY_SYSTEM_SIZE`, gsid fails with
"Failed to start installation with requested size: 0".

1. Decompress the `.xz` archive and re-compress as gzip:
   ```bash
   xz -d -v ROG5_I005D-stockvendor-GAPPS-userdebug-20261023.img.xz
   gzip -k ROG5_I005D-stockvendor-GAPPS-userdebug-20261023.img
   ```
2. Push the gzip image to device storage and start DSU installation, passing the raw image size in bytes
   (recompute it for every build — it changes between builds):
   ```bash
   adb push ROG5_I005D-stockvendor-GAPPS-userdebug-20261023.img.gz /sdcard/
   adb shell am start-activity \
       -n com.android.dynsystem/com.android.dynsystem.VerificationActivity \
       -a android.os.image.action.START_INSTALL \
       -d file:///sdcard/ROG5_I005D-stockvendor-GAPPS-userdebug-20261023.img.gz \
       --el KEY_SYSTEM_SIZE $(stat -c%s ROG5_I005D-stockvendor-GAPPS-userdebug-20261023.img) \
       --el KEY_USERDATA_SIZE 17179869184
   ```
3. Tap **Restart** from the Android system notification once installation is finished.
   If the image fails to boot, DSU discards the session on the next reboot and the stock system returns.

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
