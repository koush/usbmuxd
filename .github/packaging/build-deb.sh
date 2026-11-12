#!/bin/bash
set -euo pipefail
[[ "${VERSION:?Set VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+vysor\.[0-9]+$ ]]
export DEBIAN_FRONTEND=noninteractive
source_dir=${SOURCE_DIR:-/src}
output_dir=${OUTPUT_DIR:-/src/out}
apt-get update
apt-get install -y --no-install-recommends build-essential debhelper autoconf \
  automake libtool pkg-config libusb-1.0-0-dev libplist-dev \
  libimobiledevice-dev libimobiledevice-glue-dev git ca-certificates

# Work away from the bind mount; generated files never modify the checkout.
git -C "$source_dir" -c safe.directory="$source_dir" archive HEAD | tar -x -C /tmp
cp -r "$source_dir/.github/packaging/debian" /tmp/debian
cd /tmp
version="$VERSION+deb13"
cat > debian/changelog <<EOF
usbmuxd ($version) trixie; urgency=medium

  * Vysor Valeria-compatible usbmuxd release.

 -- Vysor <support@vysor.io>  $(date -R)
EOF
# git-version-gen needs a version when building an exported source tree.
printf '%s\n' "$VERSION" > .tarball-version
cp COPYING.GPLv2 debian/copyright
mkdir -p "$output_dir"
chmod +x debian/rules
tar --exclude='./out' -czf "$output_dir/usbmuxd_${version}_source.tar.gz" .
dpkg-buildpackage -us -uc -b
cp "/usbmuxd_${version}_amd64.deb" "$output_dir/"

# Verify that the replacement installs over Debian's stock daemon, its shared
# libraries resolve, and its version entry point runs. No USB hardware required.
apt-get install -y usbmuxd
apt-get install -y "$output_dir/usbmuxd_${version}_amd64.deb"
usbmuxd --version
! ldd /usr/sbin/usbmuxd | grep 'not found'
test -f /usr/lib/systemd/system/usbmuxd.service
test -f /usr/lib/udev/rules.d/39-usbmuxd.rules
test -f /usr/lib/udev/rules.d/70-usbmuxd.rules
grep -F 'TAG+="uaccess"' /usr/lib/udev/rules.d/70-usbmuxd.rules
getent passwd usbmux
cd "$output_dir"
sha256sum *.deb *_source.tar.gz > SHA256SUMS
