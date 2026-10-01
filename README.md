# gentoo-OrcaSlicer

Gentoo portage overlay for [OrcaSlicer](https://github.com/SoftFever/OrcaSlicer) - a G-code generator for 3D printers (Bambu, Prusa, Voron, VzBot, and more).

## Overlay packages

| Package | Version | Description |
|---------|---------|-------------|
| `media-gfx/orcaslicer` | 2.3.2, 9999 | OrcaSlicer (stable + live ebuild) |
| `x11-libs/wxGTK:3.3-gtk3-orca` | 3.3.2 | Orca's wxWidgets fork (slotted to avoid conflicts) |
| `media-libs/draco` | 1.5.7 | Google Draco 3D compression library |
| `dev-libs/libnoise` | 1.0 | Coherent noise generation library |

Most OrcaSlicer dependencies (clipper2, mcut, md4c, qoi, etc.) are bundled in `deps_src/` and built automatically - only `draco` and `libnoise` require system-level ebuilds because OrcaSlicer uses `find_package()` for them.

## Installation

### Add the overlay

```bash
mkdir -p /etc/portage/repos.conf

cat > /etc/portage/repos.conf/gentoo-orcaslicer.conf << 'EOF'
[gentoo-orcaslicer]
location = /var/db/repos/gentoo-orcaslicer
sync-type = git
sync-uri = https://github.com/kwasek404/gentoo-OrcaSlicer.git
priority = 50
EOF

emaint sync -r gentoo-orcaslicer
```

### Accept keywords and USE flags

```bash
mkdir -p /etc/portage/package.accept_keywords /etc/portage/package.use

echo '*/*::gentoo-orcaslicer ~amd64' > /etc/portage/package.accept_keywords/gentoo-orcaslicer

cat > /etc/portage/package.use/orcaslicer << 'EOF'
media-libs/opencv contrib -contribdnn
net-misc/curl adns
media-libs/qhull static-libs
x11-libs/wxGTK:3.3-gtk3-orca opengl gstreamer webkit
dev-libs/boost nls
media-libs/freetype harfbuzz
media-libs/harfbuzz icu
app-crypt/gcr gtk
EOF
```

Some dependencies may need `~amd64` keyword acceptance:

```bash
cat >> /etc/portage/package.accept_keywords/deps << 'EOF'
sci-libs/opencascade ~amd64
media-gfx/openvdb ~amd64
media-libs/opencv ~amd64
sci-mathematics/cgal ~amd64
EOF
```

### Emerge

```bash
emerge -av media-gfx/orcaslicer
```

## Docker test build

The repository includes a `Containerfile` for build validation:

```bash
docker build -f Containerfile -t gentoo-orcaslicer-test .
```

This builds in three stages:
1. Overlay dependencies (`draco`, `libnoise`)
2. wxGTK fork
3. OrcaSlicer itself

## Project status

**Work in progress** - the overlay is under active development. Build testing in Docker containers is ongoing. GitHub Actions automation for release tracking and CI is planned.

## License

The overlay metadata and ebuilds are distributed under the [GPL-2](LICENSE) license, consistent with Gentoo overlay conventions. OrcaSlicer itself is licensed under AGPL-3.
