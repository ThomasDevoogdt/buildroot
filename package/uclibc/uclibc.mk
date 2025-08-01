################################################################################
#
# uclibc
#
################################################################################

UCLIBC_VERSION = 1.0.54
UCLIBC_SOURCE = uClibc-ng-$(UCLIBC_VERSION).tar.xz
UCLIBC_SITE = https://downloads.uclibc-ng.org/releases/$(UCLIBC_VERSION)
UCLIBC_LICENSE = LGPL-2.1+
UCLIBC_LICENSE_FILES = COPYING.LIB
UCLIBC_INSTALL_STAGING = YES
UCLIBC_CPE_ID_VENDOR = uclibc-ng_project
UCLIBC_CPE_ID_PRODUCT = uclibc-ng

# uclibc is part of the toolchain so disable the toolchain dependency
UCLIBC_ADD_TOOLCHAIN_DEPENDENCY = NO

# Before uClibc is configured, we must have the first stage
# cross-compiler and the kernel headers
UCLIBC_DEPENDENCIES = host-gcc-initial linux-headers

# specifying UCLIBC_CONFIG_FILE on the command-line overrides the .config
# setting.
# check-package disable Ifdef
ifndef UCLIBC_CONFIG_FILE
UCLIBC_CONFIG_FILE = $(call qstrip,$(BR2_UCLIBC_CONFIG))
endif

UCLIBC_KCONFIG_EDITORS = menuconfig nconfig
UCLIBC_KCONFIG_FILE = $(UCLIBC_CONFIG_FILE)
UCLIBC_KCONFIG_FRAGMENT_FILES = $(call qstrip,$(BR2_UCLIBC_CONFIG_FRAGMENT_FILES))

# UCLIBC_MAKE_FLAGS set HOSTCC to the default HOSTCC, which may be
# wrapped with ccache. However, host-ccache may not already be built
# and installed when we apply the configuration, so we override that
# to use the non-ccached host compiler.
UCLIBC_KCONFIG_OPTS = \
	$(UCLIBC_MAKE_FLAGS) \
	HOSTCC="$(HOSTCC_NOCCACHE)" \
	PREFIX=$(STAGING_DIR) \
	DEVEL_PREFIX=/usr/ \
	RUNTIME_PREFIX=$(STAGING_DIR)/

UCLIBC_TARGET_ARCH = $(call qstrip,$(BR2_UCLIBC_TARGET_ARCH))

UCLIBC_GENERATE_LOCALES = $(call qstrip,$(BR2_GENERATE_LOCALE))

ifeq ($(UCLIBC_GENERATE_LOCALES),)
# We need at least one locale
UCLIBC_LOCALES = en_US
else
# Strip out the encoding part of locale names, if any
UCLIBC_LOCALES = \
	$(foreach locale,$(UCLIBC_GENERATE_LOCALES),\
	$(firstword $(subst .,$(space),$(locale))))
endif

# noMMU binary formats
ifeq ($(BR2_BINFMT_FDPIC),y)
define UCLIBC_BINFMT_CONFIG
	$(call KCONFIG_DISABLE_OPT,UCLIBC_FORMAT_FLAT,$(@D)/.config)
	$(call KCONFIG_DISABLE_OPT,UCLIBC_FORMAT_FLAT_SEP_DATA,$(@D)/.config)
	$(call KCONFIG_ENABLE_OPT,UCLIBC_FORMAT_FDPIC_ELF,$(@D)/.config)
endef
endif
ifeq ($(BR2_BINFMT_FLAT),y)
define UCLIBC_BINFMT_CONFIG
	$(call KCONFIG_ENABLE_OPT,UCLIBC_FORMAT_FLAT)
	$(call KCONFIG_DISABLE_OPT,UCLIBC_FORMAT_FLAT_SEP_DATA)
	$(call KCONFIG_DISABLE_OPT,UCLIBC_FORMAT_FDPIC_ELF)
endef
endif

#
# 64-bit time_t is enabled by default but needs headers >= 5.1.0
#
ifeq ($(BR2_TOOLCHAIN_HEADERS_AT_LEAST_5_1),)
define UCLIBC_DISABLE_TIME64
	$(call KCONFIG_DISABLE_OPT,UCLIBC_USE_TIME64)
endef
endif

#
# AArch64 definitions
#

ifeq ($(UCLIBC_TARGET_ARCH),aarch64)
UCLIBC_ARM64_PAGE_SIZE = CONFIG_AARCH64_PAGE_SIZE_$(call qstrip,$(BR2_ARM64_PAGE_SIZE))
define UCLIBC_AARCH64_PAGE_SIZE_CONFIG
	$(SED) '/CONFIG_AARCH64_PAGE_SIZE_*/d' $(@D)/.config
	$(call KCONFIG_ENABLE_OPT,$(UCLIBC_ARM64_PAGE_SIZE))
endef
endif # aarch64

#
# ARC definitions
#

ifeq ($(UCLIBC_TARGET_ARCH),arc)
UCLIBC_ARC_PAGE_SIZE = CONFIG_ARC_PAGE_SIZE_$(call qstrip,$(BR2_ARC_PAGE_SIZE))
define UCLIBC_ARC_PAGE_SIZE_CONFIG
	$(SED) '/CONFIG_ARC_PAGE_SIZE_*/d' $(@D)/.config
	$(call KCONFIG_ENABLE_OPT,$(UCLIBC_ARC_PAGE_SIZE))
endef

ifeq ($(BR2_ARC_ATOMIC_EXT),)
define UCLIBC_ARC_ATOMICS_CONFIG
	$(call KCONFIG_DISABLE_OPT,CONFIG_ARC_HAS_ATOMICS)
endef
endif

endif # arc

#
# ARM definitions
#

ifeq ($(UCLIBC_TARGET_ARCH),arm)
define UCLIBC_ARM_ABI_CONFIG
	$(SED) '/CONFIG_ARM_.ABI/d' $(@D)/.config
	$(call KCONFIG_ENABLE_OPT,CONFIG_ARM_EABI)
endef

ifeq ($(BR2_BINFMT_FLAT),y)
define UCLIBC_ARM_BINFMT_FLAT
	$(call KCONFIG_DISABLE_OPT,DOPIC)
endef
endif

# context functions are written with ARM instructions. Therefore, if
# we are using a Thumb2-only platform (i.e, Cortex-M), they must be
# disabled. Thumb1 platforms are not a problem, since they all also
# support the ARM instructions.
ifeq ($(BR2_ARM_INSTRUCTIONS_THUMB2):$(BR2_ARM_CPU_HAS_ARM),y:)
define UCLIBC_ARM_NO_CONTEXT_FUNCS
	$(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_CONTEXT_FUNCS)
endef
endif

endif # arm

#
# m68k/coldfire definitions
#

ifeq ($(UCLIBC_TARGET_ARCH),m68k)

# disable DOPIC for flat without separate data
ifeq ($(BR2_BINFMT_FLAT),y)
define UCLIBC_M68K_BINFMT_FLAT
	$(call KCONFIG_DISABLE_OPT,DOPIC)
endef
endif

endif # m68k/coldfire

#
# MIPS definitions
#

ifeq ($(UCLIBC_TARGET_ARCH),mips)
UCLIBC_MIPS_ABI = CONFIG_MIPS_$(call qstrip,$(BR2_UCLIBC_MIPS_ABI))_ABI
define UCLIBC_MIPS_ABI_CONFIG
	$(SED) '/CONFIG_MIPS_[NO].._ABI/d' $(@D)/.config
	$(call KCONFIG_ENABLE_OPT,$(UCLIBC_MIPS_ABI))
endef

UCLIBC_MIPS_NAN = CONFIG_MIPS_NAN_$(call qstrip,$(BR2_UCLIBC_MIPS_NAN))
define UCLIBC_MIPS_NAN_CONFIG
	$(SED) '/CONFIG_MIPS_NAN_.*/d' $(@D)/.config
	$(call KCONFIG_ENABLE_OPT,$(UCLIBC_MIPS_NAN))
endef
endif # mips

#
# SH definitions
#

ifeq ($(UCLIBC_TARGET_ARCH),sh)
UCLIBC_SH_TYPE = CONFIG_$(call qstrip,$(BR2_UCLIBC_SH_TYPE))
define UCLIBC_SH_TYPE_CONFIG
	$(SED) '/CONFIG_SH[234A]*/d' $(@D)/.config
	$(call KCONFIG_ENABLE_OPT,$(UCLIBC_SH_TYPE))
endef
endif # sh

#
# SPARC definitions
#

ifeq ($(UCLIBC_TARGET_ARCH),sparc)
UCLIBC_SPARC_TYPE = CONFIG_SPARC_$(call qstrip,$(BR2_UCLIBC_SPARC_TYPE))
define UCLIBC_SPARC_TYPE_CONFIG
	$(SED) 's/^\(CONFIG_[^_]*[_]*SPARC[^=]*\)=.*/# \1 is not set/g' \
		$(@D)/.config
	$(call KCONFIG_ENABLE_OPT,$(UCLIBC_SPARC_TYPE))
endef
endif # sparc

#
# PowerPC definitions
#

ifeq ($(UCLIBC_TARGET_ARCH),powerpc)
UCLIBC_POWERPC_TYPE = CONFIG_$(call qstrip,$(BR2_UCLIBC_POWERPC_TYPE))
define UCLIBC_POWERPC_TYPE_CONFIG
	$(call KCONFIG_DISABLE_OPT,CONFIG_GENERIC)
	$(call KCONFIG_DISABLE_OPT,CONFIG_E500)
	$(call KCONFIG_ENABLE_OPT,$(UCLIBC_POWERPC_TYPE))
endef
endif # powerpc

#
# x86 definitions
#
ifeq ($(UCLIBC_TARGET_ARCH),i386)
UCLIBC_X86_TYPE = CONFIG_$(call qstrip,$(BR2_UCLIBC_X86_TYPE))
define UCLIBC_X86_TYPE_CONFIG
	$(call KCONFIG_ENABLE_OPT,$(UCLIBC_X86_TYPE))
endef
endif

#
# Debug
#
ifeq ($(BR2_ENABLE_RUNTIME_DEBUG),y)
define UCLIBC_DEBUG_CONFIG
	$(call KCONFIG_ENABLE_OPT,DODEBUG)
endef
endif

#
# Endianness
#

ifeq ($(call qstrip,$(BR2_ENDIAN)),BIG)
define UCLIBC_ENDIAN_CONFIG
	$(call KCONFIG_ENABLE_OPT,ARCH_BIG_ENDIAN)
	$(call KCONFIG_ENABLE_OPT,ARCH_WANTS_BIG_ENDIAN)
	$(call KCONFIG_DISABLE_OPT,ARCH_LITTLE_ENDIAN)
	$(call KCONFIG_DISABLE_OPT,ARCH_WANTS_LITTLE_ENDIAN)
endef
else
define UCLIBC_ENDIAN_CONFIG
	$(call KCONFIG_ENABLE_OPT,ARCH_LITTLE_ENDIAN)
	$(call KCONFIG_ENABLE_OPT,ARCH_WANTS_LITTLE_ENDIAN)
	$(call KCONFIG_DISABLE_OPT,ARCH_BIG_ENDIAN)
	$(call KCONFIG_DISABLE_OPT,ARCH_WANTS_BIG_ENDIAN)
endef
endif

#
# MMU
#

ifeq ($(BR2_USE_MMU),y)
define UCLIBC_MMU_CONFIG
	$(call KCONFIG_ENABLE_OPT,ARCH_HAS_MMU)
	$(call KCONFIG_ENABLE_OPT,ARCH_USE_MMU)
endef
else
define UCLIBC_MMU_CONFIG
	$(call KCONFIG_DISABLE_OPT,ARCH_HAS_MMU)
	$(call KCONFIG_DISABLE_OPT,ARCH_USE_MMU)
endef
endif

#
# IPv6
#

UCLIBC_IPV6_CONFIG = $(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_IPV6)

#
# soft-float
#

ifeq ($(BR2_SOFT_FLOAT),y)
define UCLIBC_FLOAT_CONFIG
	$(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_FPU)
	$(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_FLOATS)
	$(call KCONFIG_ENABLE_OPT,DO_C99_MATH)
endef
else
define UCLIBC_FLOAT_CONFIG
	$(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_FPU)
	$(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_FLOATS)
endef
endif

#
# SSP
#
ifeq ($(BR2_TOOLCHAIN_BUILDROOT_USE_SSP),y)
define UCLIBC_SSP_CONFIG
	$(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_SSP)
	$(call KCONFIG_ENABLE_OPT,UCLIBC_BUILD_SSP)
endef
else
define UCLIBC_SSP_CONFIG
	$(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_SSP)
	$(call KCONFIG_DISABLE_OPT,UCLIBC_BUILD_SSP)
endef
endif

#
# Threads
#
ifeq ($(BR2_PTHREADS_NONE),y)
define UCLIBC_THREAD_CONFIG
	$(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_THREADS)
	$(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_LINUXTHREADS)
	$(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_THREADS_NATIVE)
endef
else ifeq ($(BR2_PTHREADS),y)
define UCLIBC_THREAD_CONFIG
	$(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_THREADS)
	$(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_LINUXTHREADS)
	$(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_THREADS_NATIVE)
endef
else ifeq ($(BR2_PTHREADS_NATIVE),y)
define UCLIBC_THREAD_CONFIG
	$(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_THREADS)
	$(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_LINUXTHREADS)
	$(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_THREADS_NATIVE)
endef
endif

#
# Thread debug
#

ifeq ($(BR2_PTHREAD_DEBUG),y)
UCLIBC_THREAD_DEBUG_CONFIG = $(call KCONFIG_ENABLE_OPT,PTHREADS_DEBUG_SUPPORT)
else
UCLIBC_THREAD_DEBUG_CONFIG = $(call KCONFIG_DISABLE_OPT,PTHREADS_DEBUG_SUPPORT)
endif

#
# Locale
#

ifeq ($(BR2_TOOLCHAIN_BUILDROOT_LOCALE),y)
define UCLIBC_LOCALE_CONFIG
	$(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_LOCALE)
	$(call KCONFIG_DISABLE_OPT,UCLIBC_BUILD_ALL_LOCALE)
	$(call KCONFIG_ENABLE_OPT,UCLIBC_BUILD_MINIMAL_LOCALE)
	$(call KCONFIG_SET_OPT,UCLIBC_BUILD_MINIMAL_LOCALES,"$(UCLIBC_LOCALES)")
	$(call KCONFIG_DISABLE_OPT,UCLIBC_PREGENERATED_LOCALE_DATA)
	$(call KCONFIG_DISABLE_OPT,DOWNLOAD_PREGENERATED_LOCALE_DATA)
	$(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_XLOCALE)
	$(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_GLIBC_DIGIT_GROUPING)
endef
else
define UCLIBC_LOCALE_CONFIG
	$(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_LOCALE)
endef
endif

#
# wchar
#

ifeq ($(BR2_TOOLCHAIN_BUILDROOT_WCHAR),y)
UCLIBC_WCHAR_CONFIG = $(call KCONFIG_ENABLE_OPT,UCLIBC_HAS_WCHAR)
else
UCLIBC_WCHAR_CONFIG = $(call KCONFIG_DISABLE_OPT,UCLIBC_HAS_WCHAR)
endif

#
# static/shared libs
#

ifeq ($(BR2_STATIC_LIBS),y)
UCLIBC_SHARED_LIBS_CONFIG = $(call KCONFIG_DISABLE_OPT,HAVE_SHARED)
else
UCLIBC_SHARED_LIBS_CONFIG = $(call KCONFIG_ENABLE_OPT,HAVE_SHARED)
endif

#
# Commands
#

UCLIBC_EXTRA_CFLAGS = $(TARGET_ABI) $(TARGET_DEBUGGING)

# uClibc-ng does not build with LTO, so explicitly disable it
# when using a compiler that may have support for LTO
ifeq ($(BR2_TOOLCHAIN_GCC_AT_LEAST_4_7),y)
UCLIBC_EXTRA_CFLAGS += -fno-lto
endif

UCLIBC_MAKE_FLAGS = \
	ARCH="$(UCLIBC_TARGET_ARCH)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	UCLIBC_EXTRA_CFLAGS="$(UCLIBC_EXTRA_CFLAGS)" \
	HOSTCC="$(HOSTCC)"

define UCLIBC_KCONFIG_FIXUP_CMDS
	$(call KCONFIG_SET_OPT,CROSS_COMPILER_PREFIX,"$(TARGET_CROSS)")
	$(call KCONFIG_ENABLE_OPT,TARGET_$(UCLIBC_TARGET_ARCH))
	$(call KCONFIG_SET_OPT,TARGET_ARCH,"$(UCLIBC_TARGET_ARCH)")
	$(call KCONFIG_SET_OPT,KERNEL_HEADERS,"$(LINUX_HEADERS_DIR)/usr/include")
	$(call KCONFIG_SET_OPT,RUNTIME_PREFIX,"/")
	$(call KCONFIG_SET_OPT,DEVEL_PREFIX,"/usr")
	$(call KCONFIG_SET_OPT,SHARED_LIB_LOADER_PREFIX,"/lib")
	$(call KCONFIG_DISABLE_OPT,DOSTRIP)
	$(UCLIBC_MMU_CONFIG)
	$(UCLIBC_BINFMT_CONFIG)
	$(UCLIBC_DISABLE_TIME64)
	$(UCLIBC_AARCH64_PAGE_SIZE_CONFIG)
	$(UCLIBC_ARC_PAGE_SIZE_CONFIG)
	$(UCLIBC_ARC_ATOMICS_CONFIG)
	$(UCLIBC_ARM_ABI_CONFIG)
	$(UCLIBC_ARM_BINFMT_FLAT)
	$(UCLIBC_ARM_NO_CONTEXT_FUNCS)
	$(UCLIBC_M68K_BINFMT_FLAT)
	$(UCLIBC_MIPS_ABI_CONFIG)
	$(UCLIBC_MIPS_NAN_CONFIG)
	$(UCLIBC_SH_TYPE_CONFIG)
	$(UCLIBC_SPARC_TYPE_CONFIG)
	$(UCLIBC_POWERPC_TYPE_CONFIG)
	$(UCLIBC_X86_TYPE_CONFIG)
	$(UCLIBC_DEBUG_CONFIG)
	$(UCLIBC_ENDIAN_CONFIG)
	$(UCLIBC_IPV6_CONFIG)
	$(UCLIBC_FLOAT_CONFIG)
	$(UCLIBC_SSP_CONFIG)
	$(UCLIBC_THREAD_CONFIG)
	$(UCLIBC_THREAD_DEBUG_CONFIG)
	$(UCLIBC_LOCALE_CONFIG)
	$(UCLIBC_WCHAR_CONFIG)
	$(UCLIBC_SHARED_LIBS_CONFIG)
endef

define UCLIBC_BUILD_CMDS
	$(MAKE) -C $(@D) $(UCLIBC_MAKE_FLAGS) headers
	$(MAKE) -C $(@D) $(UCLIBC_MAKE_FLAGS)
	$(MAKE) -C $(@D)/utils \
		PREFIX=$(HOST_DIR) \
		HOSTCC="$(HOSTCC)" hostutils
endef

ifeq ($(BR2_UCLIBC_INSTALL_UTILS),y)
define UCLIBC_INSTALL_UTILS_TARGET
	$(MAKE1) -C $(@D) \
		CC="$(TARGET_CC)" CPP="$(TARGET_CPP)" LD="$(TARGET_LD)" \
		ARCH="$(UCLIBC_TARGET_ARCH)" \
		PREFIX=$(TARGET_DIR) \
		utils install_utils
endef
endif

define UCLIBC_INSTALL_TARGET_CMDS
	$(MAKE1) -C $(@D) \
		$(UCLIBC_MAKE_FLAGS) \
		PREFIX=$(TARGET_DIR) \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=/ \
		install_runtime
	$(UCLIBC_INSTALL_UTILS_TARGET)
endef

# STATIC has no ld* tools, only getconf
ifeq ($(BR2_STATIC_LIBS),)
define UCLIBC_INSTALL_UTILS_STAGING
	$(INSTALL) -D -m 0755 $(@D)/utils/ldd.host $(HOST_DIR)/bin/ldd
	ln -sf ldd $(HOST_DIR)/bin/$(GNU_TARGET_NAME)-ldd
	$(INSTALL) -D -m 0755 $(@D)/utils/ldconfig.host $(HOST_DIR)/bin/ldconfig
	ln -sf ldconfig $(HOST_DIR)/bin/$(GNU_TARGET_NAME)-ldconfig
endef
endif

define UCLIBC_INSTALL_STAGING_CMDS
	$(MAKE1) -C $(@D) \
		$(UCLIBC_MAKE_FLAGS) \
		PREFIX=$(STAGING_DIR) \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=/ \
		install_runtime install_dev
	$(UCLIBC_INSTALL_UTILS_STAGING)
endef

# Checks to give errors that the user can understand
# Must be before we call to kconfig-package
ifeq ($(BR2_PACKAGE_UCLIBC)$(BR_BUILDING),yy)
ifeq ($(call qstrip,$(BR2_UCLIBC_CONFIG)),)
$(error No uClibc configuration file specified, check your BR2_UCLIBC_CONFIG setting)
endif
endif

$(eval $(kconfig-package))
