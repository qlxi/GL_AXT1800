include $(TOPDIR)/rules.mk

PKG_NAME:=default-settings
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/default-settings
	SECTION:=luci
	CATEGORY:=LuCI
	TITLE:=Custom default settings for m0eak's AXT1800 build
	PKGARCH:=all
	DEPENDS:=+luci
endef

define Package/default-settings/description
	Applies custom default settings on first boot (fancontrol, LEDs, turboacc, etc.).
endef

# This is a pure config package, no compilation needed
define Build/Compile
endef

define Package/default-settings/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/zzz $(1)/etc/uci-defaults/zzz
endef

$(eval $(call BuildPackage,default-settings))
