#!/bin/bash

function main() {
  echo "ROM Build Script"
  echo
  run ci_configure
  run messaging_init
  run src_sync 
  run repopick_changes
  run rom_build
  run rom_upload
}

