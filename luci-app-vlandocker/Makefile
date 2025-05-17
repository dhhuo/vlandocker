include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/package.mk

PKG_NAME:=luci-app-vlandocker
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

LUCI_TITLE:=VLAN Docker Setup
LUCI_DEPENDS:=+docker +luci-base +luci-mod-admin-full +dnsmasq-full
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=$(LUCI_TITLE)
  MAINTAINER:=YourName <you@example.com>
  DEPENDS:=$(LUCI_DEPENDS)
endef

define Package/$(PKG_NAME)/description
LuCI app to configure VLAN and Docker macvlan networking with DHCP support.
endef

define Build/Compile
	# No build needed for Lua/JS-only package
	true
endef

define Package/$(PKG_NAME)/install
	# LuCI controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luasrc/controller/vlandocker.lua $(1)/usr/lib/lua/luci/controller/vlandocker.lua

	# CBI model
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) ./luasrc/model/cbi/vlandocker.lua $(1)/usr/lib/lua/luci/model/cbi/vlandocker.lua

	# View: main directory
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/vlandocker
	$(CP) -r ./luasrc/view/vlandocker/* $(1)/www/luci-static/resources/view/vlandocker/

	# View: individual file
	$(INSTALL_DATA) ./luasrc/view/vlandocker_status.htm $(1)/www/luci-static/resources/view/vlandocker_status.htm

	# Shell script
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./root/usr/bin/setup_vlan_docker_with_dhcp.sh $(1)/usr/bin/setup_vlan_docker_with_dhcp.sh

	# Apply script
	$(INSTALL_DIR) $(1)/etc/vlandocker
	$(INSTALL_BIN) ./scripts/vlandocker_apply.sh $(1)/etc/vlandocker/vlandocker_apply.sh
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
