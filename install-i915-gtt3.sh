#!/bin/sh
# Install the i915kms.ko built by build-i915-gtt3.sh (GTT mmap version 3 on 15.1).
# Keeps the pkg module as /boot/modules/i915kms.ko.pkg-6.12.85_2 and creates a boot environment.
# Rollback: cp -p /boot/modules/i915kms.ko.pkg-6.12.85_2 /boot/modules/i915kms.ko && reboot
# Note: pkg upgrade/reinstall of drm-612-kmod overwrites this module.
set -eu
base=${BASE:-$(cd "$(dirname "$0")" && pwd)}
new=$base/drm-kmod-6.12.85_3/obj$base/drm-kmod-6.12.85_3/i915/i915kms.ko
orig=/boot/modules/i915kms.ko.pkg-6.12.85_2
/usr/bin/objdump -d --no-show-raw-insn "$new" | grep -A3 '<i915_gem_mmap_gtt_version>:' | grep -Eq 'movl[[:space:]]+[$]0x3, %eax'
bectl create "pre-i915-gtt3-$(date +%Y%m%d-%H%M)"
[ -e "$orig" ] || cp -p /boot/modules/i915kms.ko "$orig"
install -o root -g wheel -m 444 "$new" /boot/modules/i915kms.ko
kldxref /boot/modules
sha256 /boot/modules/i915kms.ko "$orig"
echo INSTALL-OK
