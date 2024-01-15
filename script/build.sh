#!/bin/bash

set -e

echo "OpenCV Version: $1"

CUR_DIR=$PWD
WORK_DIR=$PWD/work_dir
mkdir -p $WORK_DIR

OPENCV_SOURCE_DIR=$WORK_DIR/opencv_$1
OPENCV_SOURCE_CONTRIB_DIR=$WORK_DIR/opencv_contrib_$1

if [[ ! -d "$OPENCV_SOURCE_DIR" ]]; then
    echo "下载OpenCV 源码 ...."
    git clone --single-branch --depth 1 -b $1 https://github.com/opencv/opencv.git $OPENCV_SOURCE_DIR
fi

if [[ ! -d "$OPENCV_SOURCE_CONTRIB_DIR" ]]; then
    echo "下载 wechat_qrcode 源码 ...."
    # git clone https://github.com/opencv/opencv_contrib $OPENCV_SOURCE_CONTRIB_DIR
    git clone --single-branch --depth 1 -b $1 https://github.com/opencv/opencv_contrib $OPENCV_SOURCE_CONTRIB_DIR
    
    cd $OPENCV_SOURCE_CONTRIB_DIR
    # git checkout -b ios-model-file-support c10b07de6d9fcc3222fd4d9ec865b99fd1798e2f
    # 修复 iOS 端无法加载模型文件
    # git apply $CUR_DIR/patch/0001-add-iOS-model-file-support.patch
    # git add .
    # git commit -m "add iOS model file support"
    cd $CUR_DIR
fi

WECHAT_QR_CODE_SOURCE_DIR=$WORK_DIR/opencv_contrib_wechat_qrcode

rm -rf $WECHAT_QR_CODE_SOURCE_DIR
mkdir -p $WECHAT_QR_CODE_SOURCE_DIR/modules

OUT_DIR=$WORK_DIR/ios

function build_opencv() {
    
    if [[ ! -d "$OUT_DIR/opencv2.xcframework" ]]; then
        echo "开始编译 ...."
        cp -rf $OPENCV_SOURCE_CONTRIB_DIR/modules/wechat_qrcode $WECHAT_QR_CODE_SOURCE_DIR/modules
        
        cd $WORK_DIR
        python $OPENCV_SOURCE_DIR/platforms/apple/build_xcframework.py \
        --opencv $OPENCV_SOURCE_DIR \
        --contrib $WECHAT_QR_CODE_SOURCE_DIR \
        --without stitching \
        --without world \
        --without highgui \
        --without imgcodecs \
        --without gapi \
        --without photo \
        --without ml \
        --without java \
        --without python \
        --without js \
        --without ts \
        --without video \
        --without videoio \
        --build_only_specified_archs \
        --iphoneos_deployment_target "15.0" \
        --iphoneos_archs "arm64" \
        --iphonesimulator_archs "arm64" \
        --disable-bitcode \
        --out $OUT_DIR
    fi
}

build_opencv 

POD_DIR=$CUR_DIR/WeChatQRCodeScanner
mkdir -p $POD_DIR/Frameworks $POD_DIR/Models

rsync -a --delete $OUT_DIR/iphoneos/build/build-arm64-iphoneos/downloads/wechat_qrcode $POD_DIR/Models
rsync -a --delete $OUT_DIR/opencv2.xcframework $POD_DIR/Frameworks


LIB_DIR_NAME=lib-v$1
rm -rf $WORK_DIR/$LIB_DIR_NAME
rm -rf $WORK_DIR/$LIB_DIR_NAME.zip
mkdir -p $WORK_DIR/$LIB_DIR_NAME
rsync -a --delete $OUT_DIR/iphoneos/build/build-arm64-iphoneos/downloads/wechat_qrcode $WORK_DIR/$LIB_DIR_NAME
rsync -a --delete $OUT_DIR/opencv2.xcframework $WORK_DIR/$LIB_DIR_NAME

cd $WORK_DIR
tar -czf $WORK_DIR/$LIB_DIR_NAME.tar.gz -C $WORK_DIR $LIB_DIR_NAME
cd $CUR_DIR

# exit -1