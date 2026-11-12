# freebsd-drm-i915-gtt3

![FreeBSD](https://img.shields.io/badge/FreeBSD-15.1-AB2B28?logo=freebsd)
![drm-kmod](https://img.shields.io/badge/drm--612--kmod-6.12.85-blue)
![issue](https://img.shields.io/badge/drm--kmod-%23464-orange)
![status](https://img.shields.io/badge/status-testing-yellow)

Intel GPU hangs on FreeBSD 15.1 with `drm-612-kmod-6.12.85` from the
`quarterly` package branch, and the one-line change that stops them.

## Symptom

The desktop freezes, but the mouse cursor still moves. `kwin_x11` (or another
compositor) spins at 100% CPU. The log shows repeated GPU hangs, in any process
that draws with the GPU: Xorg, kwin, Plasma, browsers, slicers.

```
drmn0: [drm] GPU HANG: ecode 8:1:85dfffff, in MainThread [100930]
drmn0: [drm] Resetting rcs0 for stopped heartbeat on rcs0
drmn0: [drm] Xorg[100930] context reset due to GPU hang
```

Seen on a Broadwell laptop (HD Graphics 5500, PCI ID `8086:1616`). There were
no hangs on `drm-66-kmod`. The first hang came 90 minutes after `pkg upgrade`
replaced it with `drm-612-kmod`, and there were 62 in the month after.

## Cause

`i915_gem_mmap_gtt_version()` tells userspace which memory mapping interface
the kernel supports. In `drm_v6.12.85_3` the FreeBSD check is:

```c
#if __FreeBSD_version < 1500508 || (__FreeBSD_version >= 1600000 && __FreeBSD_version < 1600015)
	return 3;
#else
	return 5;
#endif
```

FreeBSD 15.1-RELEASE is `1501000`, so it gets **5**. `drm-66-kmod` always
returned 3. Mesa reads this value (`I915_PARAM_MMAP_GTT_VERSION`): from 4 up,
iris (OpenGL) and anv (Vulkan) map every buffer through
`DRM_IOCTL_I915_GEM_MMAP_OFFSET` instead of the legacy `GEM_MMAP` ioctl.
FreeBSD 15.1 does not support that path fully.

Upstream drm-kmod fixed the check in
[1d054ae556](https://github.com/freebsd/drm-kmod/commit/1d054ae55685c45c23aa86541427dfc72afa9ca1)
("i915: FreeBSD: Fix vulkan on FreeBSD 15.1"), released in `drm_v6.12.110_1`.
The commit only mentions Vulkan. As of 2026-11-12 the `2026Q4` ports branch
still ships `drm_v6.12.85_3`, so every FreeBSD 15.1 machine with an Intel GPU
on the default `quarterly` packages gets version 5.

The GPU error state agrees: the user batch ran to `MI_BATCH_BUFFER_END`, and
the engine then stalled in the vertex shader with the kernel's `PIPE_CONTROL`
waiting for it (see [error-state-excerpt.txt](error-state-excerpt.txt)).

## Fix

[i915-gtt-version-15.1.patch](i915-gtt-version-15.1.patch) is the upstream
commit. It changes `1600000` to `1501000` in the version check, so 15.1
gets 3 again. The rebuilt module differs from the packaged one by one
instruction (`mov $0x5,%eax` → `mov $0x3,%eax`).

The simplest real fix is `drm-612-kmod` built from the `latest` ports branch
(6.12.110), or waiting until it reaches `quarterly`. The scripts below rebuild
only the packaged version with this one change, to test it in isolation.

## Usage

Needs `/usr/src` for the running release.

```sh
sh build-i915-gtt3.sh           # fetches drm_v6.12.85_3, patches, builds i915kms.ko (~3 min)
sudo sh install-i915-gtt3.sh    # boot environment, backup, install
sudo shutdown -r now
```

Rollback:

```sh
sudo cp -p /boot/modules/i915kms.ko.pkg-6.12.85_2 /boot/modules/i915kms.ko
sudo shutdown -r now
```

`pkg upgrade` or a reinstall of `drm-612-kmod` overwrites the module.

## Status

Installed 2026-11-12 17:05 UTC. No GPU hangs since then, including with the
application that triggered one within minutes before. See
[CHANGELOG.md](CHANGELOG.md) for the test record.

## Links

- drm-kmod issue [#464](https://github.com/freebsd/drm-kmod/issues/464) "GPU crashes with 6.12; corrupted display"
- Findings posted to #464: https://github.com/freebsd/drm-kmod/issues/464#issuecomment-6832466975
- Ports MFH request for 2026Q4: [PR 300726](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=300726)
- Write-up: https://tradik.com/blog/freebsd-drm-i915-gtt-version-gpu-hang/
- Mesa `has_mmap_offset`: `src/intel/dev/i915/intel_device_info.c`
