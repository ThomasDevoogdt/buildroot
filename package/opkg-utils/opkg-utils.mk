################################################################################
#
# opkg-utils
#
################################################################################

OPKG_UTILS_VERSION = 0.4.3
OPKG_UTILS_SITE = http://git.yoctoproject.org/git/opkg-utils
OPKG_UTILS_SITE_METHOD = git
OPKG_UTILS_LICENSE = GPL-2.0+
OPKG_UTILS_LICENSE_FILES = COPYING

HOST_OPKG_UTILS_DEPENDENCIES += $(BR2_PYTHON3_HOST_DEPENDENCY)

define HOST_OPKG_UTILS_BUILD_CMDS
	$(MAKE) -C $(@D) $(HOST_CONFIGURE_OPTS)
endef

define HOST_OPKG_UTILS_INSTALL_CMDS
	$(MAKE) -C $(@D) PREFIX=$(HOST_DIR) install
endef

$(eval $(host-generic-package))
