################################################################################
#
# util-linux
#
################################################################################

# When making changes to this file, please check if
# util-linux-libs/util-linux-libs.mk needs to be updated accordingly as well.

UTIL_LINUX_VERSION_MAJOR = 2.41
UTIL_LINUX_VERSION = $(UTIL_LINUX_VERSION_MAJOR).5
UTIL_LINUX_SOURCE = util-linux-$(UTIL_LINUX_VERSION).tar.xz
UTIL_LINUX_SITE = $(BR2_KERNEL_MIRROR)/linux/utils/util-linux/v$(UTIL_LINUX_VERSION_MAJOR)

# README.licensing claims that some files are GPL-2.0 only, but this is not
# true. Some files are GPL-3.0+ but only in tests and in hwclock (the meson
# build has no option to drop the GPL-3.0+ date parser of hwclock).
# rfkill uses an ISC-style license.
UTIL_LINUX_LICENSE = \
	GPL-2.0+, \
	BSD-4-Clause, \
	LGPL-2.1+ (libblkid, libfdisk, libmount), \
	BSD-3-Clause (libuuid), \
	BSD-2-Clause (xxhash), \
	ISC (rfkill), \
	MIT (hardlink, flock)
UTIL_LINUX_LICENSE_FILES = README.licensing \
	Documentation/licenses/COPYING.BSD-2-Clause \
	Documentation/licenses/COPYING.BSD-3-Clause \
	Documentation/licenses/COPYING.BSD-4-Clause-UC \
	Documentation/licenses/COPYING.EUPL-1.2 \
	Documentation/licenses/COPYING.GPL-2.0-only \
	Documentation/licenses/COPYING.GPL-2.0-or-later \
	Documentation/licenses/COPYING.GPL-3.0-or-later \
	Documentation/licenses/COPYING.ISC \
	Documentation/licenses/COPYING.LGPL-2.1-or-later \
	Documentation/licenses/COPYING.MIT

ifeq ($(BR2_PACKAGE_UTIL_LINUX_HWCLOCK),y)
UTIL_LINUX_LICENSE += , GPL-3.0+ (hwclock)
endif

UTIL_LINUX_CPE_ID_VENDOR = kernel

# 0003-loopdev-use-openat2-RESOLVE_NO_SYMLINKS-for-backing-.patch
UTIL_LINUX_IGNORE_CVES += CVE-2026-27456

UTIL_LINUX_INSTALL_STAGING = YES
UTIL_LINUX_DEPENDENCIES = \
	host-bison \
	host-flex \
	host-pkgconf \
	$(if $(BR2_PACKAGE_LIBXCRYPT),libxcrypt) \
	$(if $(BR2_PACKAGE_UTIL_LINUX_LIBS),util-linux-libs) \
	$(TARGET_NLS_DEPENDENCIES)
UTIL_LINUX_CONF_OPTS += \
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
	-Dfs-search-path=/sbin:/usr/sbin \
	-Dnls=$(if $(BR2_SYSTEM_ENABLE_NLS),enabled,disabled)

HOST_UTIL_LINUX_DEPENDENCIES = host-bison host-flex host-pkgconf

# We also don't want the host-python dependency
HOST_UTIL_LINUX_CONF_OPTS = \
	-Dprogram-tests=false \
	-Dtranslate-docs=disabled \
	-Dbuild-bash-completion=disabled \
	-Dbuild-liblastlog2=disabled \
	-Dbuild-pam-lastlog2=disabled \
	-Dbuild-plymouth-support=disabled \
	-Dbuild-python=disabled \
	-Dbuild-pylibmount=disabled \
	-Dnls=disabled \
	-Dsystemd=disabled

ifeq ($(BR2_PACKAGE_UTIL_LINUX_UUIDD),y)
define UTIL_LINUX_USERS
	uuidd -1 uuidd -1 * - - - uuidd user
endef
endif

ifneq ($(BR2_PACKAGE_UTIL_LINUX_BINARIES)$(BR2_PACKAGE_UTIL_LINUX_CRAMFS)$(BR2_PACKAGE_UTIL_LINUX_FSCK)$(BR2_PACKAGE_UTIL_LINUX_LOSETUP),)
UTIL_LINUX_SELINUX_MODULES = fstools
endif

# meson only installs below the prefix: /usr/{bin,sbin} by default. Without
# merged usr, keep the binaries in /bin and /sbin, so they still overwrite
# the ones installed by busybox, and so that agetty is in /sbin.
ifeq ($(BR2_ROOTFS_MERGED_USR),y)
# Ditto for /usr/sbin and /usr/bin when merge sbin is in use
ifeq ($(BR2_ROOTFS_MERGED_BIN),y)
UTIL_LINUX_CONF_OPTS += -Dsbindir=bin
endif
else
UTIL_LINUX_CONF_OPTS += -Dbindir=/bin -Dsbindir=/sbin
endif

ifeq ($(BR2_PACKAGE_SYSTEMD),y)
UTIL_LINUX_CONF_OPTS += -Dsystemd=enabled
UTIL_LINUX_DEPENDENCIES += systemd
else
# libudev is only looked up when the systemd option is not disabled,
# and libsystemd is not found without systemd.
ifeq ($(BR2_PACKAGE_HAS_UDEV),y)
UTIL_LINUX_CONF_OPTS += -Dsystemd=auto
UTIL_LINUX_DEPENDENCIES += udev
else
UTIL_LINUX_CONF_OPTS += -Dsystemd=disabled
endif
endif

ifeq ($(BR2_PACKAGE_NCURSES),y)
UTIL_LINUX_DEPENDENCIES += ncurses
ifeq ($(BR2_PACKAGE_NCURSES_WCHAR),y)
UTIL_LINUX_CONF_OPTS += -Dncursesw=enabled -Dncurses=disabled
else
UTIL_LINUX_CONF_OPTS += -Dncursesw=disabled -Dncurses=enabled -Dwidechar=disabled
endif
else
ifeq ($(BR2_USE_WCHAR),y)
UTIL_LINUX_CONF_OPTS += -Dwidechar=enabled
else
UTIL_LINUX_CONF_OPTS += -Dwidechar=disabled
endif
UTIL_LINUX_CONF_OPTS += -Dncursesw=disabled -Dncurses=disabled
endif

# if ncurses is not available, try to fallback onto slang
ifeq ($(BR2_PACKAGE_SLANG):$(BR2_PACKAGE_NCURSES),y:)
UTIL_LINUX_DEPENDENCIES += slang
UTIL_LINUX_CONF_OPTS += -Dslang=enabled
else
UTIL_LINUX_CONF_OPTS += -Dslang=disabled
endif

# workaround for static_assert on uclibc-ng < 1.0.42
UTIL_LINUX_CFLAGS = $(TARGET_CFLAGS) -Dstatic_assert=_Static_assert

ifeq ($(BR2_PACKAGE_LIBSELINUX),y)
UTIL_LINUX_DEPENDENCIES += libselinux
UTIL_LINUX_CONF_OPTS += -Dselinux=enabled
else
UTIL_LINUX_CONF_OPTS += -Dselinux=disabled
define UTIL_LINUX_SELINUX_PAMFILES_TWEAK
	$(foreach f,su su-l,
		$(SED) '/^.*pam_selinux.so.*$$/d' \
			$(TARGET_DIR)/etc/pam.d/$(f)
	)
endef
endif

# Used by setpriv
UTIL_LINUX_DEPENDENCIES += $(if $(BR2_PACKAGE_LIBCAP_NG),libcap-ng)

# Used by cramfs utils
UTIL_LINUX_DEPENDENCIES += $(if $(BR2_PACKAGE_ZLIB),zlib)

# Used by login-utils
UTIL_LINUX_DEPENDENCIES += $(if $(BR2_PACKAGE_LINUX_PAM),linux-pam)

# Used by hardlink
UTIL_LINUX_DEPENDENCIES += $(if $(BR2_PACKAGE_PCRE2),pcre2)

# Disable/Enable utilities
# Programs of the basic set, without a dedicated option: there is no
# --enable-all-programs in meson, so every program has to be listed. Use auto
# instead of enabled, like --enable-all-programs did, as some of them depend on
# kernel headers that are missing on older toolchains (e.g. linux/blkzoned.h)
# and fail to configure when explicitly enabled.
UTIL_LINUX_BASIC_PROGRAMS = \
	bits blkdiscard blkpr blkzone blockdev chcpu choom col colcrt colrm \
	ctrlaltdel dmesg enosys exch fadvise fdisks findfs findmnt flock \
	fsfreeze fstrim getopt hexdump isosize ldattach look lsblk lsclocks \
	lsirq lslocks lsns mcookie mkfs namei pipesz rev rtcwake script \
	scriptutils setarch swapoff swapon whereis

# Every program, used to disable all of them when none are wanted
UTIL_LINUX_ALL_PROGRAMS = \
	$(UTIL_LINUX_BASIC_PROGRAMS) \
	agetty bfs cal chfn-chsh chmem cramfs eject fallocate fdformat fsck \
	hardlink hwclock ipcmk ipcrm ipcs irqtop kill last line logger login \
	losetup lsfd lslogins lsmem mesg minix more mount mountpoint newgrp \
	nologin nsenter partx pg pivot_root raw rename rfkill runuser \
	schedutils setpriv setterm su sulogin switch_root tunelp ul unshare \
	utmpdump uuidd vipw waitpid wall wdctl wipefs write zramctl

UTIL_LINUX_CONF_OPTS += \
	$(foreach p,$(UTIL_LINUX_BASIC_PROGRAMS),-Dbuild-$(p)=$(if $(BR2_PACKAGE_UTIL_LINUX_BINARIES),auto,disabled)) \
	-Dbuild-agetty=$(if $(BR2_PACKAGE_UTIL_LINUX_AGETTY),enabled,disabled) \
	-Dbuild-bfs=$(if $(BR2_PACKAGE_UTIL_LINUX_BFS),enabled,disabled) \
	-Dbuild-cal=$(if $(BR2_PACKAGE_UTIL_LINUX_CAL),enabled,disabled) \
	-Dbuild-chfn-chsh=$(if $(BR2_PACKAGE_UTIL_LINUX_CHFN_CHSH),enabled,disabled) \
	-Dbuild-chmem=$(if $(BR2_PACKAGE_UTIL_LINUX_CHMEM),enabled,disabled) \
	-Dbuild-cramfs=$(if $(BR2_PACKAGE_UTIL_LINUX_CRAMFS),enabled,disabled) \
	-Dbuild-eject=$(if $(BR2_PACKAGE_UTIL_LINUX_EJECT),enabled,disabled) \
	-Dbuild-fallocate=$(if $(BR2_PACKAGE_UTIL_LINUX_FALLOCATE),enabled,disabled) \
	-Dbuild-fdformat=$(if $(BR2_PACKAGE_UTIL_LINUX_FDFORMAT),enabled,disabled) \
	-Dbuild-fsck=$(if $(BR2_PACKAGE_UTIL_LINUX_FSCK),enabled,disabled) \
	-Dbuild-hardlink=$(if $(BR2_PACKAGE_UTIL_LINUX_HARDLINK),enabled,disabled) \
	-Dbuild-hwclock=$(if $(BR2_PACKAGE_UTIL_LINUX_HWCLOCK),enabled,disabled) \
	-Dbuild-ipcmk=$(if $(BR2_PACKAGE_UTIL_LINUX_IPCMK),enabled,disabled) \
	-Dbuild-ipcrm=$(if $(BR2_PACKAGE_UTIL_LINUX_IPCRM),enabled,disabled) \
	-Dbuild-ipcs=$(if $(BR2_PACKAGE_UTIL_LINUX_IPCS),enabled,$(if $(BR2_PACKAGE_UTIL_LINUX_BINARIES),auto,disabled)) \
	-Dbuild-irqtop=$(if $(BR2_PACKAGE_UTIL_LINUX_IRQTOP),enabled,disabled) \
	-Dbuild-kill=$(if $(BR2_PACKAGE_UTIL_LINUX_KILL),enabled,disabled) \
	-Dbuild-last=$(if $(BR2_PACKAGE_UTIL_LINUX_LAST),enabled,disabled) \
	-Dbuild-libblkid=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBBLKID),enabled,disabled) \
	-Dbuild-libfdisk=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBFDISK),enabled,disabled) \
	-Dbuild-libmount=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBMOUNT),enabled,disabled) \
	-Dbuild-libsmartcols=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBSMARTCOLS),enabled,disabled) \
	-Dbuild-libuuid=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBUUID),enabled,disabled) \
	-Dbuild-line=$(if $(BR2_PACKAGE_UTIL_LINUX_LINE),enabled,disabled) \
	-Dbuild-logger=$(if $(BR2_PACKAGE_UTIL_LINUX_LOGGER),enabled,disabled) \
	-Dbuild-login=$(if $(BR2_PACKAGE_UTIL_LINUX_LOGIN),enabled,disabled) \
	-Dbuild-losetup=$(if $(BR2_PACKAGE_UTIL_LINUX_LOSETUP),enabled,disabled) \
	-Dbuild-lsfd=$(if $(BR2_PACKAGE_UTIL_LINUX_LSFD),enabled,disabled) \
	-Dbuild-lslogins=$(if $(BR2_PACKAGE_UTIL_LINUX_LSLOGINS),enabled,disabled) \
	-Dbuild-lsmem=$(if $(BR2_PACKAGE_UTIL_LINUX_LSMEM),enabled,disabled) \
	-Dbuild-mesg=$(if $(BR2_PACKAGE_UTIL_LINUX_MESG),enabled,disabled) \
	-Dbuild-minix=$(if $(BR2_PACKAGE_UTIL_LINUX_MINIX),enabled,disabled) \
	-Dbuild-more=$(if $(BR2_PACKAGE_UTIL_LINUX_MORE),enabled,disabled) \
	-Dbuild-mount=$(if $(BR2_PACKAGE_UTIL_LINUX_MOUNT),enabled,disabled) \
	-Dbuild-mountpoint=$(if $(BR2_PACKAGE_UTIL_LINUX_MOUNTPOINT),enabled,disabled) \
	-Dbuild-newgrp=$(if $(BR2_PACKAGE_UTIL_LINUX_NEWGRP),enabled,disabled) \
	-Dbuild-nologin=$(if $(BR2_PACKAGE_UTIL_LINUX_NOLOGIN),enabled,disabled) \
	-Dbuild-nsenter=$(if $(BR2_PACKAGE_UTIL_LINUX_NSENTER),enabled,disabled) \
	-Dbuild-partx=$(if $(BR2_PACKAGE_UTIL_LINUX_PARTX),enabled,disabled) \
	-Dbuild-pg=$(if $(BR2_PACKAGE_UTIL_LINUX_PG),enabled,disabled) \
	-Dbuild-pivot_root=$(if $(BR2_PACKAGE_UTIL_LINUX_PIVOT_ROOT),enabled,disabled) \
	-Dbuild-raw=$(if $(BR2_PACKAGE_UTIL_LINUX_RAW),enabled,disabled) \
	-Dbuild-rename=$(if $(BR2_PACKAGE_UTIL_LINUX_RENAME),enabled,disabled) \
	-Dbuild-rfkill=$(if $(BR2_PACKAGE_UTIL_LINUX_RFKILL),enabled,disabled) \
	-Dbuild-runuser=$(if $(BR2_PACKAGE_UTIL_LINUX_RUNUSER),enabled,disabled) \
	-Dbuild-schedutils=$(if $(BR2_PACKAGE_UTIL_LINUX_SCHEDUTILS),enabled,disabled) \
	-Dbuild-setpriv=$(if $(BR2_PACKAGE_UTIL_LINUX_SETPRIV),enabled,disabled) \
	-Dbuild-setterm=$(if $(BR2_PACKAGE_UTIL_LINUX_SETTERM),enabled,disabled) \
	-Dbuild-su=$(if $(BR2_PACKAGE_UTIL_LINUX_SU),enabled,disabled) \
	-Dbuild-sulogin=$(if $(BR2_PACKAGE_UTIL_LINUX_SULOGIN),enabled,disabled) \
	-Dbuild-switch_root=$(if $(BR2_PACKAGE_UTIL_LINUX_SWITCH_ROOT),enabled,disabled) \
	-Dbuild-tunelp=$(if $(BR2_PACKAGE_UTIL_LINUX_TUNELP),enabled,disabled) \
	-Dbuild-ul=$(if $(BR2_PACKAGE_UTIL_LINUX_UL),enabled,disabled) \
	-Dbuild-unshare=$(if $(BR2_PACKAGE_UTIL_LINUX_UNSHARE),enabled,disabled) \
	-Dbuild-utmpdump=$(if $(BR2_PACKAGE_UTIL_LINUX_UTMPDUMP),enabled,disabled) \
	-Dbuild-uuidd=$(if $(BR2_PACKAGE_UTIL_LINUX_UUIDD),enabled,disabled) \
	-Dbuild-vipw=$(if $(BR2_PACKAGE_UTIL_LINUX_VIPW),enabled,disabled) \
	-Dbuild-waitpid=$(if $(BR2_PACKAGE_UTIL_LINUX_WAITPID),enabled,disabled) \
	-Dbuild-wall=$(if $(BR2_PACKAGE_UTIL_LINUX_WALL),enabled,disabled) \
	-Dbuild-wdctl=$(if $(BR2_PACKAGE_UTIL_LINUX_WDCTL),enabled,disabled) \
	-Dbuild-wipefs=$(if $(BR2_PACKAGE_UTIL_LINUX_WIPEFS),enabled,disabled) \
	-Dbuild-write=$(if $(BR2_PACKAGE_UTIL_LINUX_WRITE),enabled,disabled) \
	-Dbuild-zramctl=$(if $(BR2_PACKAGE_UTIL_LINUX_ZRAMCTL),enabled,disabled)

# In the host version of util-linux, we only require libuuid and
# libmount (plus libblkid as an indirect dependency of libmount).
# So disable all of the programs, unless BR2_PACKAGE_HOST_UTIL_LINUX is set

HOST_UTIL_LINUX_CONF_OPTS += \
	-Dbuild-libblkid=enabled \
	-Dbuild-libmount=enabled \
	-Dbuild-libuuid=enabled \
	-Dcryptsetup=disabled \
	-Dcryptsetup-dlopen=disabled \
	-Dbtrfs=disabled \
	-Deconf=disabled \
	-Dlibuser=disabled \
	-Dlibutempter=disabled \
	-Dmagic=disabled \
	-Dncurses=disabled \
	-Dncursesw=disabled \
	-Dreadline=disabled \
	-Dslang=disabled \
	-Dtinfo=disabled \
	-Dwidechar=disabled

# Disable raw command since starting from version 2.37 needs a
# work-around to build but in the end we don't need at all.
HOST_UTIL_LINUX_CONF_OPTS += \
	-Dbuild-raw=disabled

ifeq ($(BR2_PACKAGE_HOST_UTIL_LINUX),y)
HOST_UTIL_LINUX_CONF_OPTS += \
	-Dbuild-libfdisk=enabled \
	-Dbuild-libsmartcols=enabled \
	-Dzlib=enabled
# disable commands that have ncurses dependency, as well as
# other ones that are useless on the host
HOST_UTIL_LINUX_CONF_OPTS += \
	-Dbuild-agetty=disabled \
	-Dbuild-chfn-chsh=disabled \
	-Dbuild-chmem=disabled \
	-Dbuild-ipcmk=disabled \
	-Dbuild-login=disabled \
	-Dbuild-lsfd=disabled \
	-Dbuild-lslogins=disabled \
	-Dbuild-mesg=disabled \
	-Dbuild-more=disabled \
	-Dbuild-newgrp=disabled \
	-Dbuild-nologin=disabled \
	-Dbuild-nsenter=disabled \
	-Dbuild-pg=disabled \
	-Dbuild-rfkill=disabled \
	-Dbuild-runuser=disabled \
	-Dbuild-schedutils=disabled \
	-Dbuild-setpriv=disabled \
	-Dbuild-setterm=disabled \
	-Dbuild-su=disabled \
	-Dbuild-sulogin=disabled \
	-Dbuild-tunelp=disabled \
	-Dbuild-ul=disabled \
	-Dbuild-unshare=disabled \
	-Dbuild-uuidd=disabled \
	-Dbuild-vipw=disabled \
	-Dbuild-wall=disabled \
	-Dbuild-wdctl=disabled \
	-Dbuild-write=disabled \
	-Dbuild-zramctl=disabled
# Used by cramfs utils
HOST_UTIL_LINUX_DEPENDENCIES += host-zlib
else
HOST_UTIL_LINUX_CONF_OPTS += \
	-Dbuild-libfdisk=disabled \
	-Dbuild-libsmartcols=disabled \
	-Dzlib=disabled \
	$(foreach p,$(UTIL_LINUX_ALL_PROGRAMS),-Dbuild-$(p)=disabled)
endif

# Install libmount Python bindings
ifeq ($(BR2_PACKAGE_PYTHON3),y)
UTIL_LINUX_CONF_OPTS += \
	-Dbuild-python=enabled \
	-Dbuild-pylibmount=$(if $(BR2_PACKAGE_UTIL_LINUX_LIBMOUNT),enabled,disabled)
UTIL_LINUX_DEPENDENCIES += python3 host-python3
UTIL_LINUX_CONF_ENV += \
	_PYTHON_SYSCONFIGDATA_NAME=$(PKG_PYTHON_SYSCONFIGDATA_NAME) \
	PYTHONPATH=$(PYTHON3_PATH)
else
UTIL_LINUX_CONF_OPTS += -Dbuild-python=disabled -Dbuild-pylibmount=disabled
endif

ifeq ($(BR2_PACKAGE_READLINE),y)
UTIL_LINUX_CONF_OPTS += -Dreadline=enabled
UTIL_LINUX_DEPENDENCIES += readline
else
UTIL_LINUX_CONF_OPTS += -Dreadline=disabled
endif

ifeq ($(BR2_PACKAGE_AUDIT),y)
UTIL_LINUX_CONF_OPTS += -Daudit=enabled
UTIL_LINUX_DEPENDENCIES += audit
else
UTIL_LINUX_CONF_OPTS += -Daudit=disabled
endif

ifeq ($(BR2_PACKAGE_FILE),y)
UTIL_LINUX_CONF_OPTS += -Dmagic=enabled
UTIL_LINUX_DEPENDENCIES += file
else
UTIL_LINUX_CONF_OPTS += -Dmagic=disabled
endif

# Install PAM configuration files
ifeq ($(BR2_PACKAGE_UTIL_LINUX_SU)$(BR2_PACKAGE_LINUX_PAM),yy)
define UTIL_LINUX_INSTALL_PAMFILES
	$(INSTALL) -D -m 0644 package/util-linux/su.pam \
		$(TARGET_DIR)/etc/pam.d/su
	$(INSTALL) -D -m 0644 package/util-linux/su.pam \
		$(TARGET_DIR)/etc/pam.d/su-l
	$(UTIL_LINUX_SELINUX_PAMFILES_TWEAK)
endef
UTIL_LINUX_POST_INSTALL_TARGET_HOOKS += UTIL_LINUX_INSTALL_PAMFILES
endif

# Install agetty->getty symlink to avoid breakage when there's no busybox
ifeq ($(BR2_PACKAGE_UTIL_LINUX_AGETTY),y)
ifeq ($(BR2_PACKAGE_BUSYBOX),)
define UTIL_LINUX_GETTY_SYMLINK
	ln -sf agetty $(TARGET_DIR)/sbin/getty
endef
endif
endif

UTIL_LINUX_POST_INSTALL_TARGET_HOOKS += UTIL_LINUX_GETTY_SYMLINK

$(eval $(meson-package))
$(eval $(host-meson-package))

# Must be included after the meson-package call, to make sure all variables
# are available
include package/util-linux/util-linux-libs/util-linux-libs.mk
