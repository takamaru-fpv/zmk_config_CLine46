# CLine46 のファームウェアをビルドして書き込むためのコマンド
# 使い方は make help で表示される

# この Makefile があるフォルダ（zmk-config）と、その隣の zmk-ws
CONFIG_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
WS_DIR     := $(abspath $(CONFIG_DIR)/../zmk-ws)

IMAGE := zmkfirmware/zmk-build-arm:stable
BOARD := seeeduino_xiao_ble
DRIVE := /Volumes/XIAO-SENSE

# Docker のコンテナの中でビルドする
#   $(1): ビルド先のフォルダ名（right/left/reset）
#   $(2): シールド名（複数あるときは空白で区切る）
#   $(3): west build に追加で渡すオプション
define build
docker run --rm \
	-v "$(WS_DIR)":/zmk-ws \
	-v "$(CONFIG_DIR)/config":/zmk-ws/config \
	-v "$(CONFIG_DIR)":/cline46 \
	-w /zmk-ws $(IMAGE) bash -c '\
		west zephyr-export >/dev/null && \
		west build -p -s zmk/app -d build/$(1) -b $(BOARD) $(3) -- \
			-DSHIELD="$(2)" -DZMK_CONFIG=/zmk-ws/config -DZMK_EXTRA_MODULES=/cline46'
@echo "ビルドしたファイル: $(WS_DIR)/build/$(1)/zephyr/zmk.uf2"
endef

# XIAO-SENSE ドライブが表示されるまで待ってから、ビルドしたファイルをコピーする
#   $(1): ビルド先のフォルダ名（right/left/reset）
# ⚠️ macOS を前提としており、Windows や Linux 環境ではコマンドやファイルパスの修正が必要
define flash
@test -f "$(WS_DIR)/build/$(1)/zephyr/zmk.uf2" || { echo "zmk.uf2 がありません。先に make build-$(1) を実行してください"; exit 1; }
@echo "$(DRIVE) が表示されるのを待っています。書き込むデバイスで &bootloader キーを押すか、リセットボタンをすばやく2回押してください。Ctrl+C で中止できます。"
@until [ -f "$(DRIVE)/INFO_UF2.TXT" ]; do sleep 1; done
cp -X "$(WS_DIR)/build/$(1)/zephyr/zmk.uf2" "$(DRIVE)/"
@echo "書き込みました: build/$(1)/zephyr/zmk.uf2"
endef

.PHONY: help build-right build-left build-both flash-right flash-left build-flash-right build-flash-left build-reset flash-reset

help:
	@echo "make build-right        右手側をビルドする"
	@echo "make build-left         左手側をビルドする"
	@echo "make build-both         左右両方をビルドする"
	@echo "make flash-right        ビルド済みの右手側のファイルを XIAO-SENSE ドライブにコピーする"
	@echo "make flash-left         ビルド済みの左手側のファイルを XIAO-SENSE ドライブにコピーする"
	@echo "make build-flash-right  右手側をビルドして、そのまま XIAO-SENSE ドライブにコピーする"
	@echo "make build-flash-left   左手側をビルドして、そのまま XIAO-SENSE ドライブにコピーする"
	@echo "make build-reset        設定をリセットするためのファームウェア（settings_reset）をビルドする"
	@echo "make flash-reset        ビルド済みの settings_reset を XIAO-SENSE ドライブにコピーする"
	@echo ""
	@echo "⚠️ flash を含むコマンドは macOS でしか使えません。その他の環境では、Makefile を修正してください。"

build-right:
	$(call build,right,CLine46_R rgbled_adapter,-S studio-rpc-usb-uart)

build-left:
	$(call build,left,CLine46_L rgbled_adapter,)

build-both: build-right build-left

flash-right:
	$(call flash,right)

flash-left:
	$(call flash,left)

build-flash-right: build-right
	$(call flash,right)

build-flash-left: build-left
	$(call flash,left)

# 設定をリセットするためのファームウェア。左右どちらにも同じファイルを書き込む
build-reset:
	$(call build,reset,settings_reset,)

flash-reset:
	$(call flash,reset)
