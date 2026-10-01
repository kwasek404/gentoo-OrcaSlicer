# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Portable coherent noise-generating library for C++"
HOMEPAGE="https://github.com/SoftFever/Orca-deps-libnoise"
SRC_URI="https://github.com/SoftFever/Orca-deps-libnoise/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/Orca-deps-libnoise-${PV}"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"

src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=ON
	)
	cmake_src_configure
}
