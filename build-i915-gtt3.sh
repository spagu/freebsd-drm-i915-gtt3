#!/bin/sh
# Build i915kms.ko from drm-kmod drm_v6.12.85_3 (the version in pkg drm-612-kmod-6.12.85.1501000_2)
# with i915_gem_mmap_gtt_version() forced to 3 on FreeBSD 15.1, as in upstream
# drm-kmod commit 1d054ae556 ("i915: FreeBSD: Fix vulkan on FreeBSD 15.1").
# Test for GPU hangs (drm-kmod issue #464). Builds only; installing is a separate step.
set -eu
base=${BASE:-$(cd "$(dirname "$0")" && pwd)}
src=$base/drm-kmod-6.12.85_3
cd "$base"
if [ ! -d "$src" ]; then
	fetch -o drm-kmod-6.12.85_3.tar.gz \
	    https://github.com/freebsd/drm-kmod/archive/refs/tags/drm_v6.12.85_3.tar.gz
	tar xzf drm-kmod-6.12.85_3.tar.gz
	mv drm-kmod-drm_v6.12.85_3 "$src"
fi
f=$src/drivers/gpu/drm/i915/gem/i915_gem_mman.c
if ! grep -q '__FreeBSD_version >= 1501000 && __FreeBSD_version < 1600015' "$f"; then
	sed -i '' 's/(__FreeBSD_version >= 1600000 \&\& __FreeBSD_version < 1600015)/(__FreeBSD_version >= 1501000 \&\& __FreeBSD_version < 1600015)/' "$f"
fi
grep -n -A6 '^int i915_gem_mmap_gtt_version' "$f"
mkdir -p "$src/obj"
cd "$src"
export MAKEOBJDIRPREFIX="$src/obj"
make KMODS="i915" obj >/dev/null
nice -n 20 make -j4 KMODS="i915"
find "$src/obj" -name i915kms.ko -exec ls -la {} \;
echo BUILD-OK
