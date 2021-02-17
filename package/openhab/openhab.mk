################################################################################
#
# openhab
#
################################################################################

OPENHAB_VERSION = 3.0.1
OPENHAB_SITE = https://dl.bintray.com/openhab/mvn/org/openhab/distro/openhab/$(OPENHAB_VERSION)
OPENHAB_SOURCE = openhab-$(OPENHAB_VERSION).tar.gz
OPENHAB_STRIP_COMPONENTS = 0
OPENHAB_TARGET_DIR = $(TARGET_DIR)/usr/share/openhab
OPENHAB_LICENSE = EPL-2.0
OPENHAB_LICENSE_FILES = LICENSE.TXT
OPENHAB_DEPENDENCIES = openjdk
OPENHAB_EXCLUDES = *.bat *.ps1 *.psm1

define OPENHAB_INSTALL_TARGET_CMDS
	rm -rf $(OPENHAB_TARGET_DIR) && mkdir -p $(OPENHAB_TARGET_DIR)
	cp -r $(@D)/addons $(OPENHAB_TARGET_DIR)/addons
	cp -r $(@D)/conf $(OPENHAB_TARGET_DIR)/conf
	cp -r $(@D)/userdata $(OPENHAB_TARGET_DIR)/userdata
	cp -r $(@D)/runtime $(OPENHAB_TARGET_DIR)/runtime
	cp $(@D)/start.sh $(OPENHAB_TARGET_DIR)/start.sh
	$(INSTALL) -D -m 755 package/openhab/S60openhab \
		$(TARGET_DIR)/etc/init.d/S60openhab
endef

$(eval $(generic-package))
