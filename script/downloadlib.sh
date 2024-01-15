#!/bin/bash

set -e

CUR_DIR=$PWD
DOWNLOAD_DIR=$CUR_DIR/download_dir
ZIP_FILE=$DOWNLOAD_DIR/lib-v$1.tar.gz
LIB_UNZIP_DIR=$DOWNLOAD_DIR/lib-v$1

mkdir -p $DOWNLOAD_DIR

if [ ! -f $ZIP_FILE ]; then
    echo "[*] Downloading lib-v$1.tar.gz ..."
    wget https://github.com/0x1306a94/WeChatQRCodeScanner/releases/download/lib-v$1/lib-v$1.tar.gz -O $ZIP_FILE
fi

echo "[*] Unzipping lib-v$1.tar.gz ..."
tar -xzf $ZIP_FILE -C $DOWNLOAD_DIR

POD_DIR=$CUR_DIR/WeChatQRCodeScanner

mkdir -p $POD_DIR/Frameworks $POD_DIR/Models

echo "[*] Copying files to WeChatQRCodeScanner directory ..."
rsync -a --delete $LIB_UNZIP_DIR/opencv2.xcframework $POD_DIR/Frameworks
rsync -a --delete $LIB_UNZIP_DIR/wechat_qrcode $POD_DIR/Models