#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# 添加插件源码
sed -i '$a src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '$a src-git small https://github.com/kenzok8/small' feeds.conf.default
./scripts/feeds update -a && rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,sing*,smartdns} feeds/packages/utils/v2dat feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang -b 1.26 feeds/packages/lang/golang
./scripts/feeds install -a

# 2. 修改 R4A 閃存佈局 (適配 Breed 直刷)
# 採用區塊匹配，不再依賴不穩定的行號
DTS_FILE="target/linux/ramips/dts/mt7621_xiaomi_mi-router-4a-3g-v2.dtsi"
if [ -f "$DTS_FILE" ]; then
    # 刪除舊的 spi0 節點並插入 Breed 16MB 佈局
    sed -i '/&spi0 {/,/&pcie {/ { /&pcie {/!d }' "$DTS_FILE"
    sed -i '/&pcie {/i &spi0 {\n\tstatus = "okay";\n\tflash@0 {\n\t\tcompatible = "jedec,spi-nor";\n\t\treg = <0>;\n\t\tspi-max-frequency = <50000000>;\n\t\tpartitions {\n\t\t\tcompatible = "fixed-partitions";\n\t\t\t#address-cells = <1>;\n\t\t\t#size-cells = <1>;\n\t\t\tpartition@0 { label = "u-boot"; reg = <0x0 0x30000>; read-only; };\n\t\t\tpartition@30000 { label = "u-boot-env"; reg = <0x30000 0x10000>; read-only; };\n\t\t\tfactory: partition@40000 { label = "factory"; reg = <0x40000 0x10000>; read-only; };\n\t\t\tpartition@50000 { compatible = "denx,uimage"; label = "firmware"; reg = <0x50000 0xfb0000>; };\n\t\t};\n\t};\n};' "$DTS_FILE"
    echo "DTS Breed Patch applied."
fi

# 3. 修復 IMAGE_SIZE (16MB)
sed -i 's/IMAGE_SIZE := .*/IMAGE_SIZE := 16064k/' target/linux/ramips/image/mt7621.mk

# 4. 強制升級 Golang 以支持 HomeProxy
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang -b 22.x feeds/packages/lang/golang
