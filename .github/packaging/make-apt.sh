#!/bin/bash
set -euo pipefail
cd "${1:?Usage: make-apt.sh SITE_DIRECTORY}"
shopt -s nullglob
packages=(pool/main/u/usbmuxd/*.deb)
((${#packages[@]} > 0))
for package in "${packages[@]}"; do
    [[ "$(dpkg-deb -f "$package" Package)" == usbmuxd ]]
    [[ "$(dpkg-deb -f "$package" Architecture)" == amd64 ]]
done
mkdir -p dists/trixie/main/binary-amd64
# Unlike dpkg-scanpackages' default, apt-ftparchive retains every version.
apt-ftparchive packages pool > dists/trixie/main/binary-amd64/Packages
gzip -n -k -f dists/trixie/main/binary-amd64/Packages
apt-ftparchive \
    -o APT::FTPArchive::Release::Origin=Vysor \
    -o APT::FTPArchive::Release::Label=usbmuxd \
    -o APT::FTPArchive::Release::Suite=trixie \
    -o APT::FTPArchive::Release::Codename=trixie \
    -o APT::FTPArchive::Release::Architectures=amd64 \
    -o APT::FTPArchive::Release::Components=main \
    release dists/trixie > Release.tmp
mv Release.tmp dists/trixie/Release
printf '%s\n' 'Unsigned Vysor usbmuxd APT repository. Debian 13 (trixie), amd64.' > index.html
touch .nojekyll
