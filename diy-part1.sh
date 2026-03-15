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

# 1. 添加第三方插件源
sed -i '$a src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '$a src-git small https://github.com/kenzok8/small' feeds.conf.default

# 2. 修改 R4A 閃存佈局 (適配 Breed 直刷)
DTS_FILE="target/linux/ramips/dts/mt7621_xiaomi_mi-router-4a-3g-v2.dtsi"
if [ -f "$DTS_FILE" ]; then
    echo "Applying DTS Breed Patch..."
    # 刪除舊的 spi0 節點（從 &spi0 到 &pcie 之前）
    sed -i '/&spi0 {/,/&pcie {/ { /&pcie {/!d }' "$DTS_FILE"
    
    # 使用 Here Document 產生臨時 patch 檔案，避開單引號解析問題
    cat << 'EOF' > dts_patch.txt
&spi0 {
	status = "okay";
	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <50000000>;
		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;
			partition@0 { label = "u-boot"; reg = <0x0 0x30000>; read-only; };
			partition@30000 { label = "u-boot-env"; reg = <0x30000 0x10000>; read-only; };
			factory: partition@40000 { label = "factory"; reg = <0x40000 0x10000>; read-only; };
			partition@50000 { compatible = "denx,uimage"; label = "firmware"; reg = <0x50000 0xfb0000>; };
		};
	};
};
EOF
    # 將 patch 內容插入到 &pcie 之前
    sed -i '/&pcie {/r dts_patch.txt' "$DTS_FILE"
    rm dts_patch.txt
fi

# 3. 調整生成的韌體體積限制為 16MB (16064k)
sed -i 's/IMAGE_SIZE := .*/IMAGE_SIZE := 16064k/' target/linux/ramips/image/mt7621.mk

# 4. 預處理 Feeds (在 ./scripts/feeds update 之前執行)
rm -rf feeds/packages/lang/golang
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,sing*,smartdns}

# 使用golang分支
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang
