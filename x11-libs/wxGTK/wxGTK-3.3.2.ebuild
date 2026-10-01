# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

MY_PV="orca-$(ver_cut 1-3)"

DESCRIPTION="wxWidgets GTK3 fork for OrcaSlicer (SoftFever)"
HOMEPAGE="https://github.com/SoftFever/Orca-deps-wxWidgets"
SRC_URI="https://github.com/SoftFever/Orca-deps-wxWidgets/archive/refs/tags/${MY_PV}.tar.gz -> wxGTK-orca-${PV}.tar.gz"
S="${WORKDIR}/Orca-deps-wxWidgets-${MY_PV}"

LICENSE="wxWinLL-3 GPL-2"
SLOT="3.3-gtk3-orca"
KEYWORDS="~amd64"
IUSE="gstreamer opengl wayland webkit"

RDEPEND="
	>=dev-libs/glib-2.22:2
	dev-libs/expat
	media-libs/libjpeg-turbo:=
	media-libs/libpng:0=
	dev-libs/libpcre2[pcre16,pcre32,unicode]
	virtual/zlib:=
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/gdk-pixbuf:2
	x11-libs/pango
	gstreamer? (
		media-libs/gstreamer:1.0
		media-libs/gst-plugins-base:1.0
		media-libs/gst-plugins-bad:1.0
	)
	opengl? (
		virtual/opengl
		dev-libs/wayland
		media-libs/mesa[egl(+)]
	)
	webkit? ( net-libs/webkit-gtk:4.1= )
"
DEPEND="${RDEPEND}
	opengl? ( virtual/glu )
	x11-base/xorg-proto
"
BDEPEND="virtual/pkgconfig"

src_configure() {
	local mycmakeargs=(
		-DwxBUILD_SHARED=ON
		-DwxBUILD_TOOLKIT=gtk3
		-DwxBUILD_PRECOMP=OFF
		-DwxBUILD_DEBUG_LEVEL=0
		-DwxBUILD_SAMPLES=OFF
		-DwxBUILD_TESTS=OFF
		-DwxBUILD_DEMOS=OFF

		-DwxUSE_LIBPNG=sys
		-DwxUSE_ZLIB=sys
		-DwxUSE_LIBJPEG=sys
		-DwxUSE_EXPAT=sys

		-DwxUSE_MEDIACTRL=$(usex gstreamer ON OFF)
		-DwxUSE_OPENGL=$(usex opengl ON OFF)
		-DwxUSE_GLCANVAS_EGL=$(usex opengl ON OFF)
		-DwxUSE_WEBREQUEST=ON
		-DwxUSE_WEBVIEW=$(usex webkit ON OFF)
		-DwxUSE_PRIVATE_FONTS=ON
		-DwxUSE_AUI=ON
		-DwxUSE_REGEX=sys
		-DwxUSE_STC=OFF
		-DwxUSE_LIBTIFF=OFF
		-DwxUSE_NANOSVG=OFF
		-DwxUSE_LIBSDL=OFF
		-DwxUSE_XTEST=OFF
		-DwxUSE_DETECT_SM=OFF
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install

	# OrcaSlicer needs private headers for accessibility support
	local wx_include="${ED}/usr/include/wx-3.3"
	insinto /usr/include/wx-3.3/wx/private
	doins "${S}"/include/wx/private/*.h
	insinto /usr/include/wx-3.3/wx/generic/private
	doins "${S}"/include/wx/generic/private/*.h 2>/dev/null
	insinto /usr/include/wx-3.3/wx/gtk/private
	doins "${S}"/include/wx/gtk/private/*.h 2>/dev/null
}
