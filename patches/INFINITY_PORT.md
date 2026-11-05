# Patch series for Project Infinity X 16

This branch (`infinity-16`) carries the patch series exported on 2026-11-05 from the tested
Infinity X 16 tree (`/data/build`, manifest `ProjectInfinity-X/manifest` branch `16`).

- Every repo's patches form one ordered series: `NNNN-*.patch` numbers run across
  `patches/trebledroid/<repo>` and `patches/personal/<repo>`, so `scripts/apply_patches.sh`
  replays the exact commit order, including where TrebleDroid and personal patches interleave.
- Each series was verified to reproduce the tested tree exactly: applying it to the
  Infinity base (`refs/remotes/m/16`) gives the same git tree as the tested HEAD, for all
  38 repos.
- Patches that conflicted on Infinity's forks were ported by cherry-picking the commits
  from the working Lunaris 16.2 tree (3-way merges) and resolving 6 conflicts by hand;
  `personal/platform_frameworks_av/0031-audiopolicy-port-TrebleDroid-route-source-fixes-to-I.patch`
  is the one new combined port.
- `KNOWN_UNAPPLIED.txt` is empty: every patch in the series must apply cleanly.

## Patches dropped for Infinity

110 patch files from the Lunaris series have no commit on the Infinity tree and were removed:

### platform_bionic
- `personal/platform_bionic/0001-Revert-bionic-malloc-scudo-jemalloc-display.patch` — Reverts a Lunaris-only scudo/jemalloc display-allocator feature that Infinity's bionic does not have.

### platform_build
- `personal/platform_build/0002-build-Remove-llkd.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_build/0003-Allow-the-GSI-tree-to-handle-device-properties-indep.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_build_core
- `personal/platform_build_core/0001-Release-keys.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_build_target_board
- `personal/platform_build_target_board/0001-Remove-unathourized-adb.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_build_soong
- `personal/platform_build_soong/0001-fix-real-name GSI-nuke-tdgsi.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_external_selinux
- `trebledroid/platform_external_selinux/0012-Fix-secilc-on-Moto-One-Action.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_external_selinux/0013-Skip-selinux_flags-when-proc-attribute-is-unavailabl.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_frameworks_av
- `trebledroid/platform_frameworks_av/0001-APM-Restore-S-R-and-Q-behavior-respectively-for-tele.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_av/0006-audiopolicy-try-again-with-trimmed-audio-port-name-i.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_av/0019-audiopolicy-Fix-broken-mic-while-video-recording-on-.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_av/0021-Add-a-prop-to-fix-echo-on-incoming-or-outgoing-calls.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_av/0001-CameraParameters-dont-segfault-on-NULL-key-or-value.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_av/0001-Dont-segfault-if-we-get-a-NULL-parameter.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_av/0005-Add-support-for-manual-3A.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_frameworks_base
- `trebledroid/platform_frameworks_base/0003-Fix-env-empty-string-ANDROID_STORAGE.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0006-Implement-a-persistent-property-to-override-the-defa.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0007-Show-APN-Settings-for-CDMA-carriers.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0011-Always-allow-overriding-the-number-of-work-profiles.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0015-Re-implement-fnmatch-like-behaviour-for-RRO-java-sid.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0024-Allow-disabling-of-fingerprint-cleanups-needed-on-so.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0026-Revert-Remove-more-FDE-methods-from-StorageManager.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0027-SystemUI-Use-AVCProfileMain-for-screen-recorder.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0029-Call-Samsung-s-ISehSysInputDev-to-report-screen-stat.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0031-Add-Mediatek-power-hints-on-touch.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0032-Detect-Moto-dynamic-hardware-feature.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0033-Restore-getSimStateForSlotIndex-in-SubscriptionManag.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0037-FOD-support-for-Asus-Samsung-recent-Xiaomi-and-RedMa.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0038-Fix-brightness-slider-curve-for-some-devices.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0042-Add-support-for-Samsung-full-brightness-on-their-AID.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0043-Add-Samsung-sysinput.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0044-Bunch-of-FOD-stuff-commonize-refreshing-the-services.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0048-Allow-signature-spoofing-for-microG-Companion-Servic.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0049-Don-t-crash-system_server-if-we-fail-to-parse-dynami.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0050-Add-a-prop-to-disable-animation-in-for-sysui-media-c.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0053-Allow-spoofing-signingInfo-for-microG-Companion-Serv.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0054-Revert-Don-t-crash-system_server-if-we-fail-to-parse.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0055-Revert-Bunch-of-FOD-stuff-commonize-refreshing-the-s.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0058-skip-fs-verity-on-kernels-that-don-t-support-it.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_base/0059-fall-back-to-sysfs-touch-poke-when-samsung-sysinput-.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0001-Make-status-bar-paddings-overridables.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0002-Allow-disabling-of-fingerprint-cleanups-needed-on-so.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0004-Keyguard-Allow-locking-to-any-rotation-mode.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0008-SettingsProvider-Fix-NPE-in-SSAID-migration-on-legac.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0008-TelephonyManager-add-prop-to-force-SIM-slot-count.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0009-sys-input-samsung.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0010-Allow-a-prop-to-override-DOZE_SUSPEND-to-DOZE.for-Ao.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0012-Fod-andFingerprint.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0013-Fod-andFingerprint2fix.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0014-revert-fingerprint.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0019-networking-trafic.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0021-frp-unlock.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0024-fix-touch-samsung.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0026-fix-padding.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_base/0027-fix-padding2.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_frameworks_native
- `trebledroid/platform_frameworks_native/0008-FOD-support-for-Samsung-and-Asus.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_native/0009-Add-MTK-GED-KPI-support-to-fix-broken-Mediatek-gpufr.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_native/0011-Increase-SW_MAX-4.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_native/0013-SurfaceFlinger-Disable-SF-HWC-backpressure.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_native/0001-BLASTBufferQueue-Add-epoll_pwait2-fallback.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_native/0002-Add-MTK-GED-KPI-support-to-fix-broken-Mediatek-gpufr.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_frameworks_native/0003-Add-MTK-GED-KPI-support-to-fix-broken-Mediatek-gpufr2.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_frameworks_opt_telephony
- `trebledroid/platform_frameworks_opt_telephony/0004-Reintroduce-public-void-TelephonyMetrics.writeRilSen.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_opt_telephony/0005-Fix-NPE-with-1.0-and-1.1-CardStatus.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_frameworks_opt_telephony/0007-When-logging-UiccSlot-ignore-error-if-we-cant-print-.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_hardware_interfaces
- `personal/platform_hardware_interfaces/0001-compatibility_matrices-Add-kernel_config_s_4.14.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_hardware_interfaces/0002-compatibility_matrices-Bring-back-4.9-4.4.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_kernel_configs
- `personal/platform_kernel_configs/0003-Restore-q-android-4.9.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_kernel_configs/0004-Lower-q-android-4.9-requirements.patch` — Infinity uses LineageOS kernel_configs without q/; no FCM level 3/4 matrix references it.
- `personal/platform_kernel_configs/0006-Revert-Delete-p-android-4.4.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_packages_apps_Settings
- `trebledroid/platform_packages_apps_Settings/0003-Revert-Wi-Fi-Remove-Do-not-validate-option-in-CA-cer.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_packages_modules_Bluetooth
- `trebledroid/platform_packages_modules_Bluetooth/0005-On-Samsung-devices-we-need-to-tell-Audio-HAL-if-we-r.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_packages_modules_Bluetooth/0006-Add-properties-to-disable-some-features-commands-sta.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_packages_modules_Bluetooth/0007-Add-a-property-to-cap-declared-le-vendor-version.-Fo.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_Bluetooth/0001-Add-property-to-disable-APCF-extended-features.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_Bluetooth/0006-gd-hci-tolerate-SNIFF_SUBRATING-status-event-from-older-controllers.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_packages_modules_Connectivity
- `trebledroid/platform_packages_modules_Connectivity/0002-Support-non-working-BPF-maps-on-old-BPF-less-kernel.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_packages_modules_Connectivity/0005-netd-Remove-4.14-kernel-restrictions.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_packages_modules_Connectivity/0006-More-bpf-errors-ignore-there-are-some-4.14-without-t.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_packages_modules_Connectivity/0007-Revert-netdupdatable-add-back-abort-on-init-fail.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_Connectivity/0001-NetBpfLoad-Relax-all-kernel-version-and-capability-c.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_Connectivity/0003-BpfHandler-and-BpfNetMaps-convert-fatal-errors-to-no.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_Connectivity/0004-KernelUtils-allow-overriding-kernel-version-via-ro.b.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_Connectivity/0008-Bring-back-traffic-indicators-for-legacy-devices.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_Connectivity/0011-remove-if-in-commit.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_Connectivity/0012-bpfs-patches-missings-fix.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_Connectivity/0015-bpf-patch-derp.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_Connectivity/0017-fix-missing-bpf-patches-in-los.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_packages_modules_adb
- `personal/platform_packages_modules_adb/0001-remove-adb-restriction.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_packages_modules_adb/0002-Remove-adb-restriction.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_prebuilts_vndk_v29
- `personal/platform_prebuilts_vndk_v29/0001-Add-android.hardware.audio.common-util-android.hardw.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_system_bpf
- `trebledroid/platform_system_bpf/0001-Support-no-bpf-usecase.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_system_bpf/0002-Additional-bpf-less-handling.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_system_bpf/0001-bpfloader-Allow-overriding-kernel-version.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_system_bpf/0003-bpfloader-relax-kernel-version-gates-and-fatal-error.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_system_core
- `trebledroid/platform_system_core/0003-init-Do-not-start-console-service-when-debuggable.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_system_core/0004-Panic-into-recovery-rather-than-bootloader.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_system_core/0009-fs_mgr-Keep-allowing-encryptable-fstab-flag.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_system_core/0017-Ignore-dm-verity-setup-issues.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `trebledroid/platform_system_core/0028-Revert-libfiemap-Disable-loop-mapping-code.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_system_core/0001-Add-libkeyutils-from-TrebleDroid.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_system_core/0002-Restore-old-kernel-support-in-init-and-libprocessgro.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_system_sepolicy
- `trebledroid/platform_system_sepolicy/0001-Revert-Remove-28.0-compat-support.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_system_sepolicy/0003-remove-permissives-lines.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_system_sepolicy/0004-fix-sepoliffy.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_system_sepolicy/0008-fix-sepolicy2.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_system_sepolicy/0009-restore-2024-obsolete.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).
- `personal/platform_system_sepolicy/0011-fix-sepolicy-again.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_system_vold
- `trebledroid/platform_system_vold/0006-Revert-vold-remove-session-keyring-workaround-for-ol.patch` — Already in the Infinity X 16 sources, or not part of the tested tree (no commit on it).

### platform_vendor_pixel_gms
- `personal/platform_vendor_pixel_gms/0001-Slim-GApps-package-list.patch` — Written for Lunaris' GhosutoX vendor/pixel/gms; Infinity uses tejas101k vendor/google/gms with a different package list.
