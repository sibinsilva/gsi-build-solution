# Android 16 (`bp4a`) Generic System Image (GSI) — Technical Knowledge Base

This document records the root-cause analysis of Android 16 GSI boot-to-recovery failures and defines the invariant rules required to build a booting GSI.

---

## 1. Root Causes of GSI Boot-to-Recovery Failures

Side-by-side `debugfs` inspection of non-booting GSI images (3.9 GB) against verified booting GSI images (4.1 GB) identified 5 critical requirements:

### Root Cause 1: Missing `/system/bin/resetprop_phh`
- **What happened:** `phhusson/vendor_magisk` was cloned on `master` instead of `revision="android-10.0"`. On `master`, the Soong target is named `resetprop` instead of `resetprop_phh` (with `bootstrap: true`).
- **Impact:** `/system/bin/resetprop_phh` was completely absent from `system.img`. Every call to `resetprop_phh` inside `/system/etc/init/vndk.rc`, `/system/bin/rw-system.sh`, `/system/bin/phh-on-boot.sh`, and `/system/bin/phh-prop-handler.sh` failed silently during early init (`post-fs`, `post-fs-data`, `boot`).
- **Fix:** Pin `vendor/magisk` to `remote="phh" revision="android-10.0"` in `manifests/treble.xml` and apply `personal/platform_vendor_magisk/0001-Define-__BIONIC_ALIGN-if-missing.patch`.

### Root Cause 2: Stripped VNDK `v28`, `v29`, `v30` APEXes (~313 MB Missing)
- **What happened:** `prebuilts/vndk/v28`, `v29`, and `v30` were omitted from `treble.xml`, and `com.android.vndk.v28`, `v29`, `v30` were removed from `packages/modules/vndk/apex/Android.bp` and `build/make/target/product/gsi/Android.bp`.
- **Impact:** `/system/system_ext/apex/com.android.vndk.v28.apex` (94 MB), `v29.apex` (104 MB), `v30.apex` (115 MB), and `/system/lib[64]/vndk-28` & `vndk-29` symlinks were missing.
- **Fix:** Include `prebuilts/vndk/v28`, `v29`, `v30` in `manifests/treble.xml`, apply `personal/platform_prebuilts_vndk_v28/0001-remove-compact-vnd28.patch`, and keep `v28`–`v30` enabled in `packages/modules/vndk` and `build/make/target/product/gsi/Android.bp`.

### Root Cause 3: Overwritten `device/phh/treble/AndroidProducts.mk`
- **What happened:** `device/phh/treble/AndroidProducts.mk` was overwritten with custom generated makefiles that stripped the ROM's native GSI product makefile configuration, system properties, and overlays.
- **Fix:** Keep `device/phh/treble` cleanly checked out to the `android-16.0` branch from `manifests/treble.xml`.

### Root Cause 4: Missing `QcRilAm` and Outdated `treble_app` / `device/phh/treble`
- **What happened:** `packages/apps/QcRilAm` (`AndyCGYan/android_packages_apps_QcRilAm`) was missing from `treble.xml`, and `device/phh/treble` + `treble_app` were out of sync.
- **Fix:** Track `sibinsilva/device_phh_treble` (`android-16.0`), `sibinsilva/treble_app` (`master`), `sibinsilva/vendor_hardware_overlay` (`pie`), and `AndyCGYan/android_packages_apps_QcRilAm` (`master`) in `manifests/treble.xml`.

### Root Cause 5: `user` vs `userdebug` Init Flags in DSU (`ALLOW_PERMISSIVE_SELINUX`)
- **What happened:** In a `-user` build, `system/core/init/Android.bp` compiles `init` with `-DALLOW_PERMISSIVE_SELINUX=0` and `-DALLOW_FIRST_STAGE_CONSOLE=0`, which prevents DSU booting unless `/system/bin/init` is replaced with a `debuggable` (`userdebug`) `init` binary (`prebuilt/init-dsu-debug`).
- **Fix:** Building the `userdebug` variant automatically enables `debuggable` in `system/core/init/Android.bp` (`ALLOW_PERMISSIVE_SELINUX=1`, `ALLOW_LOCAL_PROP_OVERRIDE=1`, `ALLOW_FIRST_STAGE_CONSOLE=1`), so the built-in `/system/bin/init` boots out-of-the-box in DSU without any manual binary replacement.

---

## 2. Invariant Rules for Future Builds

1. **Never invent custom init/sepolicy hacks** in `device/phh/treble`, `system/core/init`, or `system/sepolicy` outside the tested patch set in `patches/trebledroid/` and `patches/personal/`.
2. **Never strip VNDK `v28`, `v29`, or `v30`** from `packages/modules/vndk` or `build/make/target/product/gsi/Android.bp`.
3. **Never revert `vendor.lge.hardware.vibrator@1.0`** in `vendor/interfaces` (`device/phh/treble/cmds/Android.bp` requires it for `vibrator-lge`).
4. **Always run `./scripts/verify_gsi.sh --all /data/build`** to validate both the source tree and the generated `system.img` before publishing a release.
5. **No `sudo` is needed** to inspect `system.img`: `/usr/sbin/debugfs -R "stat /system/..." system.img` inspects ext4 images unprivileged.
