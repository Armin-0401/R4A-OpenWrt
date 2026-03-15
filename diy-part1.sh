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
#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# 1. 添加第三方插件源
sed -i '$a src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '$a src-git small https://github.com/kenzok8/small' feeds.conf.default

# 2. 修改 R4A 閃存佈局 (適配 Breed 直刷)
# 使用區塊匹配法，精確替換 &spi0 節點，不再依賴不穩定的行號
DTS_FILE="target/linux/ramips/dts/mt7621_xiaomi_mi-router-4a-3g-v2.dtsi"
if [ -f "$DTS_FILE" ]; then
    echo "Applying DTS Breed Patch..."
    # 刪除舊的 spi0 節點
    sed -i '/&spi0 {/,/&pcie {/ { /&pcie {/!d }
    # 插入兼容 Breed 的 16MB 分區佈局
    sed -i '/&pcie {/i &spi0 {\n\tstatus = "okay";\n\tflash@0 {\n\t\tcompatible = "jedec,spi-nor";\n\t\treg = <0>;\n\t\tspi-max-frequency = <50000000>;\n\t\tpartitions {\n\t\t\tcompatible = "fixed-partitions";\n\t\t\t#address-cells = <1>;\n\t\t\t#size-cells = <1>;\n\t\t\tpartition@0 { label = "u-boot"; reg = <0x0 0x30000>; read-only; };\n\t\t\tpartition@30000 { label = "u-boot-env"; reg = <0x30000 0x10000>; read-only; };\n\t\t\tfactory: partition@40000 { label = "factory"; reg = <0x40000 0x10000>; read-only; };\n\t\t\tpartition@50000 { compatible = "denx,uimage"; label = "firmware"; reg = <0x50000 0xfb0000>; };\n\t\t};\n\t};\n};' "$DTS_FILE"
fi

# 3. 調整生成的韌體體積限制為 16MB (16064k)
sed -i 's/IMAGE_SIZE := .*/IMAGE_SIZE := 16064k/' target/linux/ramips/image/mt7621.mk

# 4. 預處理 Feeds (在 ./scripts/feeds update 之前執行)
# 刪除可能導致衝突的舊版套件定義
rm -rf feeds/packages/lang/golang
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,sing*,smartdns}

# 5. 強制更換 Golang 版本為 1.24 (支持 HomeProxy)
# 注意：這一步必須在 install -a 之前，且路徑要正確
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang
# 6. 物理刪除報錯的 shadowsocksr-libev (如果你不打算使用它)
# 這能徹底解決「即使沒勾選也會編譯並報錯」的問題
rm -rf feeds/small/shadowsocksr-libev
