# Android 16 (`bp4a`) Generic System Image (GSI) Build Solution

Complete, reproducible manifest, patch set, verification suite, and automated build scripts for building a **100% booting** Android 16 QPR2 (`BP4A.251205.006`) Generic System Image (GSI), verified booting via DSU and `fastbootd`.

---

## Repository Structure

```text
gsi-build-solution/
├── manifests/
│   └── treble.xml                 # Working .repo/local_manifests/treble.xml (Treble + VNDK v28-v30 + Magisk android-10.0 + QcRilAm)
├── patches/
│   ├── trebledroid/               # TrebleDroid platform patches (25 repos)
│   └── personal/                  # Personal & device compatibility patches (39 repos)
├── prebuilt/
│   └── init-dsu-debug             # Reference standalone debuggable init binary (needed only if testing a -user build in DSU)
├── scripts/
│   ├── setup_tree.sh              # Installs treble.xml & syncs required Treble/VNDK/Magisk repos
│   ├── apply_patches.sh           # Idempotent patch applier (proper build/make & vendor GMS mappings, zero .orig files)
│   ├── verify_gsi.sh              # Pre-build source check & post-build debugfs image verification
│   └── build_gsi.sh               # One-command end-to-end builder, verifier, and .img.xz packager
├── apply-patches.sh               # Root wrapper calling scripts/apply_patches.sh
└── KNOWLEDGE_BASE.md              # Root-cause analysis of GSI boot-to-recovery issues & architectural rules
```

---

## Quick Start (One-Command Build)

```bash
# Build userdebug variant (recommended — includes built-in DSU init support & root/adb debugging)
./scripts/build_gsi.sh /data/build userdebug /data/release

# Or build user variant
./scripts/build_gsi.sh /data/build user /data/release
```

---

## Step-by-Step Usage

### 1. Setup Manifest & Sync Treble Repos
```bash
./scripts/setup_tree.sh /data/build
```

### 2. Apply All Patches Idempotently
```bash
./scripts/apply_patches.sh /data/build
```

### 3. Verify Source Tree Before Building
```bash
./scripts/verify_gsi.sh --tree /data/build
```

### 4. Verify Built `system.img` After Building (No `sudo` Required)
```bash
./scripts/verify_gsi.sh --image /data/build /data/build/out/target/product/tdgsi_arm64_ab/system.img
```

---

## Key Requirements for a Booting Android 16 GSI

See [`KNOWLEDGE_BASE.md`](./KNOWLEDGE_BASE.md) for the complete technical breakdown:

1. **Product Target & `device/phh/treble`:**
   - Keep `device/phh/treble/AndroidProducts.mk` intact from the synced `device/phh/treble` tree (`android-16.0`) rather than overwriting it with custom generated makefiles that omit required board/product configuration.
2. **`/system/bin/resetprop_phh` Binary:**
   - `phhusson/vendor_magisk` **must** be tracked on `revision="android-10.0"` (not `master`). On `master`, the binary is named `resetprop` without `bootstrap: true`, causing `resetprop_phh` to be omitted from `/system/bin/` and breaking `vndk.rc`, `phh-on-boot.sh`, and `phh-prop-handler.sh` during early boot.
3. **VNDK `v28`, `v29`, `v30` APEXes:**
   - `prebuilts/vndk/v28`, `v29`, and `v30` must be present in `.repo/local_manifests/treble.xml`, and `com.android.vndk.v28`, `v29`, `v30` must remain enabled in `packages/modules/vndk/apex/Android.bp` and `build/make/target/product/gsi/Android.bp`.
4. **Patch Applier Directory Mapping (`apply_patches.sh`):**
   - `platform_build_core`, `platform_build_target`, and `platform_build_target_board` all target `build/make` (not `build/core` or `build/target`).
   - Do not revert `vendor.lge.hardware.vibrator@1.0` in `vendor/interfaces`; `device/phh/treble/cmds/Android.bp` builds `vibrator-lge`, which links against `vendor.lge.hardware.vibrator@1.0`.
   - `patch` must always be called with `--no-backup-if-mismatch` so `.orig` files are never left in `frameworks/` or `packages/` (which breaks Android AAPT2 compilation).
