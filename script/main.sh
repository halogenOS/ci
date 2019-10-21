#!/bin/bash

function main() {
  echo "ROM Build Script"
  echo
  export ROM_VERSION_ONLY="$(echo ${XOS_REVISION} | cut -d '-' -f2)"
  pushd /mnt/xos/$ROM_VERSION_ONLY/building/ws
  run src_sync 
  run rom_build
  run rom_upload
  popd
}

