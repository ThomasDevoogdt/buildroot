################################################################################
#
# netavark
#
################################################################################

# When updating the version here, also update aardvark-dns in lockstep
NETAVARK_VERSION = v1.15.2
NETAVARK_SITE = https://github.com/containers/netavark
NETAVARK_SITE_METHOD = git

NETAVARK_LICENSE = Apache-2.0
NETAVARK_LICENSE_FILES = LICENSE

# For protoc
NETAVARK_DEPENDENCIES = host-protobuf

NETAVARK_CARGO_ENV = PROTOC=$(HOST_DIR)/bin/protoc

# In case only nftables is enabled, use that as the firwewall backend
ifeq ($(BR2_PACKAGE_IPTABLES).$(BR2_PACKAGE_NFTABLES),.y)
define NETAVARK_CONFIG_NFTABLES
	$(Q)mkdir -p $(TARGET_DIR)/etc/containers/containers.conf.d/
	printf '[network]\nfirewall_driver = "nftables"\n' \
		> $(TARGET_DIR)/etc/containers/containers.conf.d/50-buildroot-nftables.conf
endef
NETAVARK_POST_INSTALL_TARGET_HOOKS += NETAVARK_CONFIG_NFTABLES

# See https://github.com/containers/netavark/issues/1057#issuecomment-2286149984
define NETAVARK_LINUX_CONFIG_FIXUPS_NFTABLES
	$(call KCONFIG_ENABLE_OPT,CONFIG_IPV6)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NF_TABLES)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NF_TABLES_INET)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_NUMGEN)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_CT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_FLOW_OFFLOAD)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_CONNLIMIT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_LOG)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_LIMIT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_MASQ)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_REDIR)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_NAT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_TUNNEL)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_QUEUE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_QUOTA)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_REJECT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_REJECT_INET)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_COMPAT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_HASH)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_FIB)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_FIB_INET)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_XFRM)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_SOCKET)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_TPROXY)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_SYNPROXY)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_DUP_NETDEV)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_FWD_NETDEV)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_FIB_NETDEV)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_REJECT_NETDEV)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_REJECT_IPV4)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_DUP_IPV4)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_FIB_IPV4)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_COMPAT_ARP)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_REJECT_IPV6)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_DUP_IPV6)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_FIB_IPV6)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_BRIDGE_META)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NFT_BRIDGE_REJECT)
endef
endif

define NETAVARK_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_ADVANCED)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XTABLES)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MATCH_ADDRTYPE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MATCH_COMMENT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MATCH_CONNTRACK)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MARK)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MATCH_IPVS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NF_CONNTRACK)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_IPTABLES)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_FILTER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_NAT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_TARGET_MASQUERADE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_BRIDGE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_BRIDGE_NETFILTER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NET_CORE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_VETH)
	$(NETAVARK_LINUX_CONFIG_FIXUPS_NFTABLES)
endef

$(eval $(cargo-package))
