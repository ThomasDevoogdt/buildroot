################################################################################
#
# util-linux-libs
#
################################################################################

# Please keep this file as similar as possible to util-linux.mk

UTIL_LINUX_LIBS_VERSION = $(UTIL_LINUX_VERSION)
UTIL_LINUX_LIBS_SOURCE = $(UTIL_LINUX_SOURCE)
UTIL_LINUX_LIBS_SITE = $(UTIL_LINUX_SITE)
UTIL_LINUX_LIBS_DL_SUBDIR = $(UTIL_LINUX_DL_SUBDIR)
UTIL_LINUX_LIBS_CPE_ID_VENDOR = $(UTIL_LINUX_CPE_ID_VENDOR)
UTIL_LINUX_LIBS_CPE_ID_PRODUCT = $(UTIL_LINUX_CPE_ID_PRODUCT)

# README.licensing claims that some files are GPL-2.0 only, but this is not
# true. Some files are GPL-3.0+ but only in tests and in hwclock (not built
# here). rfkill uses an ISC-style license.
UTIL_LINUX_LIBS_LICENSE = LGPL-2.1+ (libblkid, libfdisk, libmount), BSD-3-Clause (libuuid)
UTIL_LINUX_LIBS_LICENSE_FILES = README.licensing \
	Documentation/licenses/COPYING.BSD-3-Clause \
	Documentation/licenses/COPYING.LGPL-2.1-or-later

# This package is only used to build other packages that have a depdendency
# on util-linux libraries which in turn may be dependencies for the full
# util-linux build. The libraries that are actually used on target are built
# by the util-linux package.
UTIL_LINUX_LIBS_INSTALL_TARGET = NO
UTIL_LINUX_LIBS_INSTALL_STAGING = YES
UTIL_LINUX_LIBS_DEPENDENCIES = \
	host-bison \
	host-flex \
	host-pkgconf \
	$(if $(BR2_PACKAGE_LIBXCRYPT),libxcrypt) \
	$(TARGET_NLS_DEPENDENCIES)
UTIL_LINUX_LIBS_CONF_OPTS += \
	-Dprogram-tests=false \
	-Dtranslate-docs=disabled \
	-Dbuild-bash-completion=disabled \
	-Dbuild-liblastlog2=disabled \
	-Dbuild-pam-lastlog2=disabled \
	-Dbuild-plymouth-support=disabled \
	-Dcryptsetup=disabled \
	-Dcryptsetup-dlopen=disabled \
	-Dbtrfs=disabled \
	-Deconf=disabled \
	-Dlibuser=disabled \
	-Dlibutempter=disabled \
	-Dsmack=disabled \
	-Dsysvinit=disabled \
	-Dnls=$(if $(BR2_SYSTEM_ENABLE_NLS),enabled,disabled)

# systemd/eudev depend on util-linux-libs so we disable systemd and udev support
UTIL_LINUX_LIBS_CONF_OPTS += -Dsystemd=disabled

# No libs use wchar
UTIL_LINUX_LIBS_CONF_OPTS += -Dwidechar=disabled

# No libs use ncurses
UTIL_LINUX_LIBS_CONF_OPTS += -Dncursesw=disabled -Dncurses=disabled -Dslang=disabled

# workaround for static_assert on uclibc-ng < 1.0.42
UTIL_LINUX_LIBS_CFLAGS = $(TARGET_CFLAGS) -Dstatic_assert=_Static_assert

# libmount optionally uses selinux
ifeq ($(BR2_PACKAGE_UTIL_LINUX_LIBMOUNT)$(BR2_PACKAGE_LIBSELINUX),yy)
UTIL_LINUX_LIBS_DEPENDENCIES += libselinux
UTIL_LINUX_LIBS_CONF_OPTS += -Dselinux=enabled
else
UTIL_LINUX_LIBS_CONF_OPTS += -Dselinux=disabled
endif

# Disable utilities
UTIL_LINUX_LIBS_CONF_OPTS += \
	$(foreach p,$(UTIL_LINUX_ALL_PROGRAMS),-Dbuild-$(p)=disabled) \
	-Dbuild-libblkid=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBBLKID),enabled,disabled) \
	-Dbuild-libfdisk=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBFDISK),enabled,disabled) \
	-Dbuild-libmount=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBMOUNT),enabled,disabled) \
	-Dbuild-libsmartcols=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBSMARTCOLS),enabled,disabled) \
	-Dbuild-libuuid=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBUUID),enabled,disabled)

# libmount python bindings are separate, will be installed by full util-linux
UTIL_LINUX_LIBS_CONF_OPTS += -Dbuild-python=disabled -Dbuild-pylibmount=disabled

# No libs use readline
UTIL_LINUX_LIBS_CONF_OPTS += -Dreadline=disabled

# No libs use audit
UTIL_LINUX_LIBS_CONF_OPTS += -Daudit=disabled

# No libs use libmagic
UTIL_LINUX_LIBS_CONF_OPTS += -Dmagic=disabled

# No libs use zlib
UTIL_LINUX_LIBS_CONF_OPTS += -Dzlib=disabled

$(eval $(meson-package))
