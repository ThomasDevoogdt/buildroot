################################################################################
#
# jam
#
################################################################################

JAM_VERSION = 2.6.1
JAM_SOURCE = jam-$(JAM_VERSION).tar
JAM_SITE = https://swarm.workshop.perforce.com/downloads/guest/perforce_software/jam

define HOST_JAM_BUILD_CMDS
	$(HOST_CONFIGURE_OPTS) AR="$(HOSTAR) ruscU" $(MAKE) -C $(@D)
endef

define HOST_JAM_INSTALL_CMDS
	$(INSTALL) -m 0755 -D $(@D)/bin*/jam $(HOST_DIR)/bin/jam
endef

$(eval $(host-generic-package))
