#!/bin/bash
set -e

# format of tag needs to be "bnx/release/<model>/<deployment>/<version>"
TAG=$1
BUILD_NUM=$2
WORKSPACE_FOLDER=$3
DEVICE_SECRET=$4
FIRMWARE_SECRET=$5

MODEL=$(echo $TAG | cut -f3 -d/)
if [ -z "$MODEL" ]; then
    echo "Invalid model"
    exit 1
fi
echo "Model is ${MODEL}"

DEPLOYMENT=$(echo $TAG | cut -f4 -d/)
if [ "$DEPLOYMENT" == "prod" ]; then
    BNXCLOUD="bnxcloud"
else
    BNXCLOUD="bnxcloud-${DEPLOYMENT}"
fi
echo "Deployment is ${DEPLOYMENT}"

VERSION=$(echo $TAG | cut -f5 -d/)
if [ -z "$VERSION" ]; then
    echo "Invalid version"
    exit 1
fi
echo "Version is ${VERSION}"

if [ -z "$BUILD_NUM" ]; then
    echo "Invalid build number"
    exit 1
fi

if [ "$MODEL" == "BNX-2000" ]; then
    PREBUILT_VERSION="mips_24kc_gcc-7.5.0_musl"
elif [[ "$MODEL" == "BNX-2500B1" || "$MODEL" == "BNX-2500B2" ]]; then
    PREBUILT_VERSION="mipsel_24kc_gcc-11.2.0_musl"
fi

if [ ! -z "$PREBUILT_VERSION" ]; then
    PREBUILT_URL="https://s3.amazonaws.com/download.bnxcloud.com/tools/prebuilt-${PREBUILT_VERSION}.tar.bz2"
    wget $PREBUILT_URL -O prebuilt.tar.bz2
    tar xf prebuilt.tar.bz2
fi

FW_VERSION="$VERSION-$DEPLOYMENT.$BUILD_NUM"
SECRET_ARGS=
if [ ! -z "$DEVICE_SECRET" ]; then
    SECRET_ARGS="$SECRET_ARGS --device-secret $DEVICE_SECRET"
fi
if [ ! -z "$FIRMWARE_SECRET" ]; then
    SECRET_ARGS="$SECRET_ARGS --firmware-secret $FIRMWARE_SECRET"
fi

./bnx/scripts/install.sh --product $MODEL
./bnx/scripts/configure.sh --product $MODEL --bnxcloud $BNXCLOUD --version $FW_VERSION $SECRET_ARGS
make -j12 target/compile package/compile package/install target/install package/index

mkdir -p $WORKSPACE_FOLDER
echo $MODEL > $WORKSPACE_FOLDER/model.txt
echo $FW_VERSION > $WORKSPACE_FOLDER/version.txt
echo $DEPLOYMENT > $WORKSPACE_FOLDER/deployment.txt

cp .circleci/deploy.sh $WORKSPACE_FOLDER

# artifacts that will be stored
ARTIFACT_FOLDER=$WORKSPACE_FOLDER/artifacts
mkdir -p $ARTIFACT_FOLDER
[ -f bin/targets/*/*/*-sysupgrade.bin ] && cp bin/targets/*/*/*-sysupgrade.bin $ARTIFACT_FOLDER/${MODEL}-firmware-v${FW_VERSION}-sysupgrade.bin
[ -f bin/targets/*/*/*-factory.bin ] && cp bin/targets/*/*/*-factory.bin $ARTIFACT_FOLDER/${MODEL}-firmware-v${FW_VERSION}-factory.bin
[ -d bin/packages ] && cp -R bin/packages $ARTIFACT_FOLDER/
