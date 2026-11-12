# Debian releases and unsigned APT repository

The `Debian release and APT repository` workflow builds **Debian 13 (trixie),
amd64** packages. Other distributions/architectures are not currently supported;
in particular, Ubuntu 24.04 does not supply the required libplist version.
Dependencies come from Debian, not mutable upstream CI artifacts. Preflight
support remains enabled.

## Repository setup and release

1. In repository Settings → Pages, select **GitHub Actions** as the build source.
2. Allow Actions to run. No PAT or signing key is required. The workflow grants
   its publication job `contents: write`, `pages: write`, and `id-token: write`.
3. Run the workflow manually with a new version such as `1.1.1+vysor.1`, or push
   a tag named `vysor-1.1.1+vysor.1`. Use the desired source ref for manual runs.
   Bump the numeric Vysor suffix on every release. Debian packages append `+deb13`.

The workflow builds a package named `usbmuxd` with `Provides: vysor-usbmuxd`,
tests upgrading Debian's stock daemon, and publishes the `.deb`, corresponding
source (including packaging), and SHA256SUMS to a GitHub Release. Choose a version
greater than the distro package; compare using `dpkg --compare-versions`.

It then downloads Debian 13 amd64 packages from **all non-draft, non-prerelease
releases**, builds multi-version APT indexes, and deploys Pages. Published assets
are immutable by policy: use a new version rather than replacing them. If Pages
publication fails after the release is published, rerun the failed job: it verifies
the existing release checksums before continuing without replacing assets. Draft
releases can also be retried. Do not delete old releases while clients use their files.

## Install

On Debian 13 amd64, create `/etc/apt/sources.list.d/vysor-usbmuxd.list` containing:

```text
deb [arch=amd64 trusted=yes] https://koush.github.io/usbmuxd/ trixie main
```

Then run:

```sh
sudo apt update
sudo apt install usbmuxd
```

This is intentionally **unsigned**: `trusted=yes` disables APT authentication
for this repository. HTTPS transport and release checksums do not replace a
repository signature. No key installation is needed.

You can also download a release `.deb` and run `sudo apt install ./usbmuxd_*.deb`.
The package replaces the distro's `usbmuxd`; it preserves pairing records and uses
udev/systemd activation. Reconnect the phone after installation to activate the
daemon. A future higher-versioned distro package can supersede this fork; consumers
requiring the patches can depend on the virtual package `vysor-usbmuxd`.
