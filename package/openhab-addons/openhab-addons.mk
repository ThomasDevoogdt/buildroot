################################################################################
#
# openhab-addons
#
################################################################################

OPENHAB_ADDONS_VERSION = 3.1.0
OPENHAB_ADDONS_SITE = https://openhab.jfrog.io/artifactory/libs-release-local/org/openhab/distro/openhab-addons/$(OPENHAB_ADDONS_VERSION)
OPENHAB_ADDONS_SOURCE = openhab-addons-$(OPENHAB_ADDONS_VERSION).kar
OPENHAB_ADDONS_STRIP_COMPONENTS = 0
OPENHAB_ADDONS_TARGET_DIR = $(TARGET_DIR)/usr/share/openhab/addons
OPENHAB_ADDONS_LICENSE = EPL-2.0
OPENHAB_ADDONS_LICENSE_FILES = https://github.com/openhab/openhab-addons/blob/main/LICENSE
OPENHAB_ADDONS_DEPENDENCIES = openhab

define OPENHAB_ADDONS_EXTRACT_CMDS
	cp $(OPENHAB_ADDONS_DL_DIR)/$(OPENHAB_ADDONS_SOURCE) $(@D)/$(OPENHAB_ADDONS_SOURCE)
endef

define OPENHAB_ADDONS_INSTALL_TARGET_CMDS
	mkdir -p $(OPENHAB_ADDONS_TARGET_DIR)
	cp -r $(@D)/$(OPENHAB_ADDONS_SOURCE) $(OPENHAB_ADDONS_TARGET_DIR)
endef

$(eval $(generic-package))
