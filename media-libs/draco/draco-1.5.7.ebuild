# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="3D data compression library"
HOMEPAGE="https://google.github.io/draco/ https://github.com/google/draco"
SRC_URI="https://github.com/google/draco/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=""
DEPEND=""

src_configure() {
	local mycmakeargs=(
		-DDRACO_ANIMATION_ENCODING=ON
		-DDRACO_BACKWARDS_COMPATIBILITY=ON
		-DDRACO_DECODER_ATTRIBUTE_DEDUPLICATION=ON
		-DDRACO_JS_GLUE=OFF
		-DDRACO_MESH_COMPRESSION=ON
		-DDRACO_POINT_CLOUD_COMPRESSION=ON
		-DDRACO_TESTS=OFF
		-DDRACO_WASM=OFF
		-DBUILD_SHARED_LIBS=ON
	)
	cmake_src_configure
}
