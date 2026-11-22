################################################################################
#
# librsvg
#
################################################################################

LIBRSVG_VERSION_MAJOR = 2.62
LIBRSVG_VERSION = $(LIBRSVG_VERSION_MAJOR).4
LIBRSVG_SITE = $(call github,GNOME,librsvg,$(LIBRSVG_VERSION))
LIBRSVG_INSTALL_STAGING = YES
LIBRSVG_DOWNLOAD_DEPENDENCIES += host-rustc
LIBRSVG_DOWNLOAD_POST_PROCESS = cargo
LIBRSVG_DL_ENV = CARGO_HOME=$(BR_CARGO_HOME)
LIBRSVG_NINJA_ENV = \
	$(PKG_CARGO_ENV) \
	PKG_CONFIG_ALLOW_CROSS=1 \
	PKG_CONFIG_LIBDIR="$(STAGING_DIR)/usr/lib/pkgconfig:$(STAGING_DIR)/usr/share/pkgconfig" \
	PKG_CONFIG_SYSROOT_DIR="$(STAGING_DIR)"
HOST_LIBRSVG_NINJA_ENV = $(HOST_PKG_CARGO_ENV)
LIBRSVG_CONF_OPTS = \
	-Davif=disabled \
	-Ddocs=disabled \
	-Dpixbuf=enabled \
	-Dpixbuf-loader=disabled \
	-Drsvg-convert=disabled \
	-Dtests=false \
	-Dtriplet=$(RUSTC_TARGET_NAME) \
	-Dvala=disabled
HOST_LIBRSVG_CONF_OPTS = \
	-Davif=disabled \
	-Ddocs=disabled \
	-Dintrospection=disabled \
	-Dpixbuf=enabled \
	-Dpixbuf-loader=disabled \
	-Drsvg-convert=disabled \
	-Dtests=false \
	-Dvala=disabled
LIBRSVG_DEPENDENCIES = \
	cairo freetype gdk-pixbuf harfbuzz host-cargo-c host-gdk-pixbuf \
	host-rustc libglib2 libxml2 pango $(TARGET_NLS_DEPENDENCIES)
HOST_LIBRSVG_DEPENDENCIES = \
	host-cairo host-cargo-c host-freetype host-gdk-pixbuf host-harfbuzz \
	host-libglib2 host-libxml2 host-pango host-rustc
LIBRSVG_LICENSE = LGPL-2.1+, vendored dependencies licenses probably not listed
LIBRSVG_LICENSE_FILES = COPYING.LIB
LIBRSVG_CPE_ID_VENDOR = gnome

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
LIBRSVG_CONF_OPTS += -Dintrospection=enabled
LIBRSVG_DEPENDENCIES += gobject-introspection
else
LIBRSVG_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
$(eval $(host-meson-package))
