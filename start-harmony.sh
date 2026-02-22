#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR/jdMall_Harmony"

DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk

/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm install --all

DEVECO_SDK_HOME=$DEVECO_SDK_HOME /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHsp --mode module -p common

DEVECO_SDK_HOME=$DEVECO_SDK_HOME /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap --mode module -p entry

/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc install common/build/default/outputs/default/common-default-unsigned.hsp

/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc install entry/build/default/outputs/default/entry-default-unsigned.hap

/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc shell aa start -d 0 -b com.lucifer.jdmall -a EntryAbility

