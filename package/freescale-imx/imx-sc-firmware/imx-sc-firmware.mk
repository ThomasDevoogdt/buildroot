################################################################################
#
# imx-sc-firmware
#
################################################################################

IMX_SC_FIRMWARE_VERSION = 1.18.0
IMX_SC_FIRMWARE_REVISION = 654907b
IMX_SC_FIRMWARE_SITE = $(FREESCALE_IMX_SITE)
IMX_SC_FIRMWARE_SOURCE = imx-sc-firmware-$(IMX_SC_FIRMWARE_VERSION)-$(IMX_SC_FIRMWARE_REVISION).bin

IMX_SC_FIRMWARE_LICENSE = NXP Semiconductor Software License Agreement
IMX_SC_FIRMWARE_LICENSE_FILES = EULA COPYING SCR.txt
IMX_SC_FIRMWARE_REDISTRIBUTE = NO

define IMX_SC_FIRMWARE_EXTRACT_CMDS
	$(call NXP_EXTRACT_HELPER,$(IMX_SC_FIRMWARE_DL_DIR)/$(IMX_SC_FIRMWARE_SOURCE))
endef

IMX_SC_FIRMWARE_INSTALL_IMAGES = YES

# SCFW firmware is needed when generating imx8-boot-sd.bin which is
# done in post-image script.
ifeq ($(BR2_PACKAGE_FREESCALE_IMX_PLATFORM_IMX8X),y)
define IMX_SC_FIRMWARE_INSTALL_IMAGES_CMDS
	cp $(@D)/mx8qx-mek-scfw-tcm.bin $(BINARIES_DIR)/mx8qx-mek-scfw-tcm.bin
	cp $(@D)/mx8qx-val-scfw-tcm.bin $(BINARIES_DIR)/mx8qx-val-scfw-tcm.bin
endef
else ifeq ($(BR2_PACKAGE_FREESCALE_IMX_PLATFORM_IMX8DXL),y)
define IMX_SC_FIRMWARE_INSTALL_IMAGES_CMDS
	cp $(@D)/mx8dxl-evk-scfw-tcm.bin $(BINARIES_DIR)/
endef
else ifeq ($(BR2_PACKAGE_FREESCALE_IMX_PLATFORM_IMX8),y)
define IMX_SC_FIRMWARE_INSTALL_IMAGES_CMDS
	cp $(@D)/mx8qm-*-scfw-tcm.bin $(BINARIES_DIR)/
endef
endif

$(eval $(generic-package))
