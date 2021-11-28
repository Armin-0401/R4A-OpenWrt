#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)

#删除原默认主题
rm -rf package/lean/luci-theme-argon
rm -rf package/lean/luci-theme-bootstrap
rm -rf package/lean/luci-theme-material
rm -rf package/lean/luci-theme-netgear
rm -rf package/lean/luci-theme-ifit

### 修改主题文件
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/lean/luci-theme-argon

# 修改 argon 为默认主题,可根据你喜欢的修改成其他的（不选择那些会自动改变为默认主题的主题才有效果）
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 修改主机名字，把Xiaomi-R4A修改你喜欢的就行（不能纯数字或者使用中文）
sed -i '/uci commit system/i\uci set system.@system[0].hostname='Xiaomi-R4A'' package/lean/default-settings/files/zzz-default-settings

# Modify default IP
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

# 修改默认wifi名称ssid为404.not.found.lab
sed -i 's/ssid=OpenWrt/ssid=404.not.found.lab/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
