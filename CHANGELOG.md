# Changelog

## 2026-11-12
- Added `i915-gtt-version-15.1.patch`, upstream drm-kmod commit 1d054ae556, applied to `drm_v6.12.85_3`.
- Added `build-i915-gtt3.sh` (builds only `i915kms.ko`) and `install-i915-gtt3.sh` (boot environment, backup of the packaged module, install).
- Added `error-state-excerpt.txt`: registers from the GPU error state of a hang on the unpatched module. The full dump is not published because it contains application buffers.
- Test: patched module installed 17:05 UTC. The slicer that hung the GPU within minutes before ran for 15+ minutes with no hang.
- Findings posted to drm-kmod #464, with cross-references in #467 and #509. Write-up published on tradik.com. Asked for the fix to be merged to 2026Q4 in ports PR 300726.
