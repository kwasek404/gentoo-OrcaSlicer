# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

WX_GTK_VER="3.3-gtk3-orca"

inherit cmake xdg

DESCRIPTION="G-code generator for 3D printers (Bambu, Prusa, Voron, VzBot, and more)"
HOMEPAGE="https://github.com/SoftFever/OrcaSlicer"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/SoftFever/OrcaSlicer.git"
else
	SRC_URI="https://github.com/SoftFever/OrcaSlicer/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
	S="${WORKDIR}/OrcaSlicer-${PV}"
fi

LICENSE="AGPL-3 Apache-2.0 Boost-1.0 GPL-2 GPL-3 LGPL-3 MIT"
SLOT="0"
IUSE="test"

RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-libs/boost-1.83:=[nls]
	dev-cpp/tbb:=
	dev-cpp/nlohmann_json:=
	dev-libs/cereal
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/gmp:=
	dev-libs/mpfr:=
	dev-cpp/eigen:3
	media-gfx/openvdb:=
	media-libs/draco:=
	media-libs/glew:0=
	media-libs/glfw:=
	media-libs/libjpeg-turbo:=
	media-libs/libpng:0=
	media-libs/nanosvg:=
	media-libs/opencv:=[contrib(-),-contribdnn(-)]
	net-libs/webkit-gtk:4.1
	net-misc/curl[adns]
	sci-libs/nlopt
	sci-libs/opencascade:=
	sci-mathematics/cgal:=
	dev-libs/openssl:=
	dev-libs/libnoise:=
	media-libs/freetype:2
	sys-apps/dbus
	virtual/opengl
	virtual/zlib:=
	x11-libs/gtk+:3
	x11-libs/wxGTK:${WX_GTK_VER}=[opengl,gstreamer,webkit]
	app-crypt/libsecret
	media-libs/gstreamer:1.0
	media-libs/gst-plugins-base:1.0
	media-libs/gst-plugins-bad:1.0
	dev-libs/wayland
"
DEPEND="${RDEPEND}
	media-libs/qhull[static-libs]
	test? ( >=dev-cpp/catch-3.8 )
"
# OrcaSlicer 2.3.2 was developed against GCC 13-14 and does not compile
# cleanly with GCC 15 (implicit type conversions, wxGTK 3.3 API changes).
# Pin to GCC 14 until upstream adds GCC 15 support.
BDEPEND="
	sys-devel/gcc:14
	virtual/pkgconfig
	dev-build/cmake
	dev-build/ninja
"

src_prepare() {
	sed -i -e 's/OrcaSlicer-${SoftFever_VERSION}+UNKNOWN/OrcaSlicer-${SoftFever_VERSION}+Gentoo/g' version.inc || die

	# Boost.System is header-only since Boost 1.87 and no longer ships a
	# CMake target. Drop it from the find_package() COMPONENTS list.
	sed -i -e 's/COMPONENTS system filesystem/COMPONENTS filesystem/' \
		CMakeLists.txt || die

	# CGAL 6: property_map() getter now returns std::optional (.value()), while
	# add_property_map() still returns std::pair (.first). Fix getter call sites.
	perl -i -pe 's/\.first;/.value();/g if /property_map/ && !/add_property_map/' \
		src/libslic3r/CutSurface.cpp || die
	# CGAL 6: CGAL::AABB_traits renamed to CGAL::AABB_traits_3.
	sed -i -e 's/CGAL::AABB_traits</CGAL::AABB_traits_3</g' \
		src/libslic3r/CutSurface.cpp || die

	# Gentoo OpenCV 4.x: headers are in /usr/include/opencv4, and
	# there is no opencv_world library (individual modules instead).
	sed -i -e 's/find_package(OpenCV REQUIRED core)/find_package(OpenCV REQUIRED COMPONENTS core imgproc)/' \
		src/libslic3r/CMakeLists.txt || die
	sed -i -e '/find_package(OpenCV/a include_directories(${OpenCV_INCLUDE_DIRS})' \
		src/libslic3r/CMakeLists.txt || die
	sed -i -e 's/opencv_world/${OpenCV_LIBS}/' \
		src/libslic3r/CMakeLists.txt || die

	# Boost >= 1.86: boost::process now defaults to v2 API.
	# OrcaSlicer uses v1 API (child, ipstream, pipe, spawn, search_path).
	sed -i -e 's|boost/process\.hpp|boost/process/v1.hpp|' \
		-e 's|boost/process/spawn\.hpp|boost/process/v1/spawn.hpp|' \
		-e 's|boost/process/args\.hpp|boost/process/v1/args.hpp|' \
		-e 's|boost/process/windows\.hpp|boost/process/v1/windows.hpp|' \
		src/libslic3r/GCode/PostProcessor.cpp \
		src/slic3r/GUI/MediaPlayCtrl.cpp \
		src/slic3r/GUI/RemovableDriveManager.cpp \
		src/slic3r/Utils/Process.cpp || die
	sed -i -e 's|namespace process = boost::process;|namespace process = boost::process::v1;|' \
		src/libslic3r/GCode/PostProcessor.cpp || die
	sed -i -e 's|boost::process::|boost::process::v1::|g' \
		src/slic3r/GUI/MediaPlayCtrl.cpp \
		src/slic3r/GUI/RemovableDriveManager.cpp \
		src/slic3r/Utils/Process.cpp || die

	# Boost >= 1.90: directory_iterator no longer included transitively
	# by boost/filesystem/operations.hpp.
	sed -i -e '/#include <boost\/filesystem\/operations.hpp>/a #include <boost/filesystem/directory.hpp>' \
		src/slic3r/Config/Version.cpp \
		src/slic3r/Config/Snapshot.cpp || die

	# Boost >= 1.87: io_service renamed to io_context.
	sed -i -e 's/boost::asio::io_service/boost::asio::io_context/g' \
		src/slic3r/GUI/HttpServer.hpp \
		src/slic3r/Utils/Bonjour.hpp \
		src/slic3r/Utils/Bonjour.cpp \
		src/slic3r/Utils/Serial.hpp || die

	# GCC 13+: bundled mcut misses explicit <cstdint> includes.
	local mcut_files=(
		deps_src/mcut/include/mcut/internal/bvh.h
		deps_src/mcut/include/mcut/internal/frontend.h
		deps_src/mcut/include/mcut/internal/preproc.h
		deps_src/mcut/include/mcut/internal/tpool.h
		deps_src/mcut/include/mcut/internal/cdt/cdt.h
		deps_src/mcut/include/mcut/internal/cdt/kdtree.h
		deps_src/mcut/include/mcut/internal/cdt/triangulate.h
		deps_src/mcut/include/mcut/internal/cdt/utils.h
		deps_src/mcut/source/bvh.cpp
		deps_src/mcut/source/frontend.cpp
		deps_src/mcut/source/hmesh.cpp
		deps_src/mcut/source/kernel.cpp
		deps_src/mcut/source/mcut.cpp
		deps_src/mcut/source/preproc.cpp
	)
	local f
	for f in "${mcut_files[@]}"; do
		[[ -f ${f} ]] || continue
		grep -q '^#include <cstdint>' "${f}" && continue
		sed -i '1i #include <cstdint>' "${f}" || die "sed failed on ${f}"
	done

	cmake_src_prepare
}

src_configure() {
	export CC=gcc-14 CXX=g++-14
	CMAKE_BUILD_TYPE="Release"

	export WX_CONFIG="/usr/lib64/wx/config/gtk3-unicode-3.3"

	local mycmakeargs=(
		-DOPENVDB_FIND_MODULE_PATH="/usr/$(get_libdir)/cmake/OpenVDB"

		-DSLIC3R_FHS=ON
		-DSLIC3R_STATIC=OFF
		-DSLIC3R_GUI=ON
		-DSLIC3R_PCH=OFF
		-DSLIC3R_GTK=3
		-DBUILD_TESTS=$(usex test OFF OFF)
		-DORCA_TOOLS=OFF
		-Wno-dev
	)

	cmake_src_configure
}
