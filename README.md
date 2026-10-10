# zmk-config-CLine46

CLine46 の ZMK ファームウェア設定

## ローカルでビルドする方法

GitHub Actions を使わずに、手元の PC でファームウェアをビルドする手順です。Docker が使える状態になっている必要があります。

### 1. 準備

この「1. 準備」は、初めてビルドするときに1回だけ行います。2回目からは「2. ビルド」から始められます。

このリポジトリと、ZMK の作業フォルダ `zmk-ws` を、同じフォルダの中に並べて作ります。

```bash
mkdir cline46 && cd cline46
mkdir zmk-ws
git clone https://github.com/takamaru-fpv/zmk_config_CLine46.git zmk-config
```

```
cline46/
├── zmk-config/   # このリポジトリ
└── zmk-ws/       # ZMK 本体やビルドしたファイルが入る作業フォルダ
```

`cline46` フォルダで次のコマンドを実行して、ビルド用のコンテナを起動します。

```bash
docker run --rm -it \
  -v "$PWD/zmk-ws":/zmk-ws \
  -v "$PWD/zmk-config/config":/zmk-ws/config \
  -v "$PWD/zmk-config":/cline46 \
  -w /zmk-ws zmkfirmware/zmk-build-arm:stable bash
```

コンテナの中で次のコマンドを実行して、ZMK 本体とモジュールを `zmk-ws` にダウンロードします。

```bash
west init -l config
west update
```

`zmk-config/config/west.yml` を変更したときは、もう一度 `west update` を実行してください。

コマンドが終了したら、 `exit` でコンテナから抜けます。

### 2. ビルド

`cline46` フォルダで、上と同じ `docker run` のコマンドでコンテナを起動し、コンテナの中で次のコマンドを実行します。

```bash
# コンテナを起動するたびに1回実行する
west zephyr-export

# 右手側
west build -p -s zmk/app -d build/right -b seeeduino_xiao_ble -S studio-rpc-usb-uart -- \
  -DSHIELD="CLine46_R rgbled_adapter" -DZMK_CONFIG=/zmk-ws/config -DZMK_EXTRA_MODULES=/cline46

# 左手側
west build -p -s zmk/app -d build/left -b seeeduino_xiao_ble -- \
  -DSHIELD="CLine46_L rgbled_adapter" -DZMK_CONFIG=/zmk-ws/config -DZMK_EXTRA_MODULES=/cline46
```

コマンドが終了したら、 `exit` でコンテナから抜けます。

ビルドしたファームウェアは次の場所にできます。

- 右手側: `zmk-ws/build/right/zephyr/zmk.uf2`
- 左手側: `zmk-ws/build/left/zephyr/zmk.uf2`

`CLine46.keymap` や右手の設定ファイルのみを変更した場合は、右手側だけをビルドして書き込めば反映されます。

左手の設定ファイルや `config/west.yml` などを変更したときは、左手側もビルドして書き込んでください。

### 3. 書き込み

1. 書き込む側のデバイスを USB ケーブルで PC につなぐ
2. XIAO（マイコン）のリセットボタンをすばやく2回押すと `XIAO-SENSE` というドライブが表示され、ファームウェアを書き込める状態になる
    - 書き込む側のキーに `&bootloader` を割り当てている場合は、そのキーを押しても同じ状態になります
3. `zmk.uf2` を `XIAO-SENSE` ドライブにコピーする

macOS の場合は、`cline46` フォルダで次のコマンドを実行するとコピーできます。その他の OS の場合は `XIAO-SENSE` へのパスを修正するか、手動でコピーしてください。

```bash
# 右手側
cp zmk-ws/build/right/zephyr/zmk.uf2 /Volumes/XIAO-SENSE/

# 左手側
cp zmk-ws/build/left/zephyr/zmk.uf2 /Volumes/XIAO-SENSE/
```

コピーが終わると XIAO が自動で再起動し、新しいファームウェアが反映されます。

### 4. 設定をリセットする

キーボードを初期状態に戻したいときは、設定をリセットするためのファームウェア（`settings_reset`）を左右両方に書き込みます。

`settings_reset` は、「2. ビルド」と同じようにコンテナの中で次のコマンドを実行してビルドします。左右どちらにも同じファイルを書き込みます。

```bash
west build -p -s zmk/app -d build/reset -b seeeduino_xiao_ble -- \
  -DSHIELD="settings_reset" -DZMK_CONFIG=/zmk-ws/config -DZMK_EXTRA_MODULES=/cline46
```

ビルドしたファームウェアは `zmk-ws/build/reset/zephyr/zmk.uf2` にできます。

「3. 書き込み」と同じ手順で、このファイルを左右それぞれの `XIAO-SENSE` ドライブにコピーします。

macOS の場合は、`cline46` フォルダで次のコマンドを実行するとコピーできます。

```bash
cp zmk-ws/build/reset/zephyr/zmk.uf2 /Volumes/XIAO-SENSE/
```

### 5. make でまとめて実行する

macOS など `make` コマンドが使える環境では、ビルドから書き込みまでをまとめて実行できます。「1. 準備」を済ませてから、`zmk-config` フォルダに移動して実行してください。


```bash
# 例: 右手側をビルドして、そのまま書き込む
make build-flash-right
```

使えるコマンドの一覧と説明は `make help` で確認できます。

名前に `flash` が入っているコマンドは、macOS でしか使えません。その他の OS で使う場合は、`Makefile` を修正するか、手動でコピーしてください。
