# The cmake minimum version is set to either 3.18 or higher,
# depending on the highest minimum version required by any
# of the packages bundled in Buildroot. If a package is
# bumped or a new one added, and it requires a higher
# cmake version than the one provided by the host, our
# cmake infra will catch it and build its own.
#
BR2_CMAKE_VERSION_MIN = $(BR2_HOST_CMAKE_AT_LEAST)

BR2_CMAKE_CANDIDATES ?= cmake cmake3

# When host-cmake is enabled, use it for all packages.
ifeq ($(BR2_PACKAGE_HOST_CMAKE),y)
BR2_CMAKE = $(HOST_DIR)/bin/cmake
BR2_CMAKE_HOST_DEPENDENCY = host-cmake
else
BR2_CMAKE ?= $(call suitable-host-package,cmake,\
	$(BR2_CMAKE_VERSION_MIN) $(BR2_CMAKE_CANDIDATES))
ifeq ($(BR2_CMAKE),)
BR2_CMAKE = $(HOST_DIR)/bin/cmake
BR2_CMAKE_HOST_DEPENDENCY = host-cmake
endif
endif

# cmake for packages that host-ccache depends on (<PKG>_ADD_CCACHE_DEPENDENCY
# = NO). A suitable system cmake is preferred, so host-cmake can then itself
# be built with ccache. The minimum is the one required by ccache.
BR2_CMAKE_NOCCACHE_VERSION_MIN = 3.18

ifeq ($(BR2_CCACHE),y)
BR2_CMAKE_NOCCACHE ?= $(call suitable-host-package,cmake,\
	$(BR2_CMAKE_NOCCACHE_VERSION_MIN) $(BR2_CMAKE_CANDIDATES))
ifeq ($(BR2_CMAKE_NOCCACHE),)
BR2_CMAKE_NOCCACHE = $(HOST_DIR)/bin/cmake
BR2_CMAKE_NOCCACHE_HOST_DEPENDENCY = host-cmake
endif
else
BR2_CMAKE_NOCCACHE = $(BR2_CMAKE)
BR2_CMAKE_NOCCACHE_HOST_DEPENDENCY = $(BR2_CMAKE_HOST_DEPENDENCY)
endif
