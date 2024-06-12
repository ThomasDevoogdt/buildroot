################################################################################
#
# argyll-cms
#
################################################################################

ARGYLL_CMS_VERSION = 3.2.0
ARGYLL_CMS_SOURCE = Argyll_V$(ARGYLL_CMS_VERSION)_src.zip
ARGYLL_CMS_SITE = https://www.argyllcms.com
ARGYLL_CMS_LICENSE = AGPL-3.0+, GPL-2.0, GPL-3.0
ARGYLL_CMS_LICENSE_FILES = License.txt License2.txt License3.txt
ARGYLL_CMS_DEPENDENCIES = host-jam jpeg libpng openssl tiff zlib

define ARGYLL_CMS_EXTRACT_CMDS
	unzip $(ARGYLL_CMS_DL_DIR)/$(ARGYLL_CMS_SOURCE) -d $(@D)
	mv $(@D)/Argyll_V$(ARGYLL_CMS_VERSION)/* $(@D)
	rmdir $(@D)/Argyll_V$(ARGYLL_CMS_VERSION)
endef

define ARGYLL_CMS_BUILD_CMDS
	$(SED) 's/SubInclude imdi/#SubInclude imdi/g' $(@D)/Jamfile
	$(SED) 's/#SubInclude gamut/SubInclude gamut/g' $(@D)/Jamfile
	$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) \
		LINKFLAGS="$(TARGET_LDFLAGS) -ldl" \
		CCFLAGS="$(TARGET_CFLAGS) -DUNIX" \
		HDRS=$(STAGING_DIR)/usr/include \
		JAM_NEW_GNU_AR_OPTIONS=true
endef

define ARGYLL_CMS_INSTALL_TARGET_CMDS
	$(SED) 's/SubInclude gamut/#SubInclude gamut/g' $(@D)/Jamfile
	$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) \
		PREFIX=/usr DESTDIR=$(TARGET_DIR) REFSUBDIR=argyll-cms install
endef

$(eval $(generic-package))
