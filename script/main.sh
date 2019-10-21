#!/bin/bash

function main() {
  echo "ROM Build Script"
  echo
  run src_sync 
  run rom_build
  run rom_upload
}

