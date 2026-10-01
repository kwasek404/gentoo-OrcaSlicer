# Gentoo OrcaSlicer overlay build test container
# Usage: docker build -f Containerfile -t gentoo-orcaslicer-test .

FROM gentoo/portage:latest AS portage
FROM gentoo/stage3:latest

# Copy portage tree from snapshot (avoids emerge --sync)
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

# Portage configuration (binrepos.conf already in stage3 with Gentoo binhost)
RUN echo "MAKEOPTS=\"-j$(nproc) -l$(nproc)\"" >> /etc/portage/make.conf && \
    echo 'ACCEPT_LICENSE="*"' >> /etc/portage/make.conf && \
    echo 'USE="opengl gstreamer webkit wayland X gtk3 dbus"' >> /etc/portage/make.conf && \
    echo 'FEATURES="-sandbox -usersandbox -pid-sandbox -ipc-sandbox -network-sandbox parallel-fetch getbinpkg"' >> /etc/portage/make.conf

# Import Gentoo Release Engineering GPG keys for binpkg signature verification
RUN getuto

# Install overlay
COPY . /var/db/repos/gentoo-orcaslicer/

RUN mkdir -p /etc/portage/repos.conf && \
    printf '[gentoo-orcaslicer]\nlocation = /var/db/repos/gentoo-orcaslicer\npriority = 50\n' \
    > /etc/portage/repos.conf/gentoo-orcaslicer.conf

# Accept keywords for all overlay packages
RUN mkdir -p /etc/portage/package.accept_keywords && \
    echo '*/*::gentoo-orcaslicer ~amd64' \
    > /etc/portage/package.accept_keywords/gentoo-orcaslicer

# USE flags for specific packages
RUN mkdir -p /etc/portage/package.use && \
    echo 'media-libs/opencv contrib -contribdnn' \
    > /etc/portage/package.use/orcaslicer && \
    echo 'net-misc/curl adns' \
    >> /etc/portage/package.use/orcaslicer && \
    echo 'media-libs/qhull static-libs' \
    >> /etc/portage/package.use/orcaslicer && \
    echo 'x11-libs/wxGTK:3.3-gtk3-orca opengl gstreamer webkit' \
    >> /etc/portage/package.use/orcaslicer && \
    echo 'dev-libs/boost nls' \
    >> /etc/portage/package.use/orcaslicer && \
    echo 'media-libs/freetype harfbuzz' \
    >> /etc/portage/package.use/orcaslicer && \
    echo 'media-libs/harfbuzz icu' \
    >> /etc/portage/package.use/orcaslicer && \
    echo 'app-crypt/gcr gtk' \
    >> /etc/portage/package.use/orcaslicer

# Generate Manifest files for all overlay ebuilds
RUN for ebuild in /var/db/repos/gentoo-orcaslicer/*/*/*.ebuild; do \
        ebuild "${ebuild}" manifest 2>&1 || true; \
    done

# Stage 1: emerge overlay deps that use find_package() (draco, libnoise)
RUN emerge -v1 --keep-going \
    media-libs/draco \
    dev-libs/libnoise \
    || true

# Stage 2: emerge wxGTK fork (must compile from source - Orca fork)
RUN emerge -v1 x11-libs/wxGTK:3.3-gtk3-orca || true

# Stage 3: emerge OrcaSlicer (deps via binhost, orcaslicer itself from source)
RUN emerge -v media-gfx/orcaslicer || true

CMD ["/bin/bash"]
