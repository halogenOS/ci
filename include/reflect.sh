#!/bin/bash

        REFLECTORS_PATH="$TOP/include/reflectors"
CURRENT_REFLECTORS_PATH="$REFLECTORS_PATH"

export REFLECTOR_NAME=""
export REFLECTOR_ID=""

function reflectorName() {
  export REFLECTOR_NAME="$@"
}

function reflectorId() {
  export REFLECTOR_ID="$1"
}

function log() {
  logd "[reflect] $@"
}

function logv() {
  if [ "$XDBFW_VERBOSE_LOG" == "1" ]; then
    log "$@"
  fi
}

rfl_break_oo=0
rfl_nobreak_oo=1

function run() {
  echo "[reflect] run $@"
  run_bridge $rfl_break_oo $@
}

function runall() {
  echo "[reflect] runall $@"
  run_bridge $rfl_nobreak_oo $@
}

function run_bridge() {
  local oldrflp="$CURRENT_REFLECTORS_PATH"
  export CURRENT_REFLECTORS_PATH="$REFLECTORS_PATH"
  run_internal $@
  export CURRENT_REFLECTORS_PATH="$oldrflp"
}

function run_internal() {
  local breakoo="$1"
  shift 1
  local reflectresult=0
  local allargs="$@"
  local reflector="$1"
  shift 1
  local reflectargs="$@"
  local foundreflector=false
  if [ $breakoo -eq $rfl_nobreak_oo ]; then
    # set this to true because runall needs 0 or more reflectors
    foundreflector=true
  fi
  for sc in $(find $CURRENT_REFLECTORS_PATH/ -type f); do
    local reflfn="${sc/$REFLECTOR_PATH\//}"
    if [[ "$reflfn" == *".pointer" ]]; then
      local point="$(cat $sc)"
      logv "Found pointer to '$point', from '$reflfn'"
      CURRENT_REFLECTORS_PATH="$TOP/$point"
      run_internal $breakoo $allargs
      CURRENT_REFLECTORS_PATH="$REFLECTORS_PATH"
      continue
    fi
    logv "Found reflector $reflfn"
    source $sc
    local reflectresult=$?
    if [ $reflectresult -ne 0 ]; then
      echo -e "\033[91mReflector $reflfln is invalid or failed!\033[0m"
      break
    fi
    if isReflectorExample; then
      continue
    fi
    if [ "$REFLECTOR_NAME" == "$reflector" ] ||
       [ "$REFLECTOR_ID"   == "$reflector" ]; then
      logv " => Reflecting!"
      foundreflector=true
      reflect $reflectargs
      reflectresult=$?
      if [ $breakoo -eq $rfl_break_oo ]; then
        break
      fi
    fi
  done
  if ! $foundreflector; then
    echo -e "${CL_RED}${EF_BOLD}ERROR: reflector '$reflector' not found${CL_RESET}"
    exit 1
  fi
  clean_reflection
  logv "[reflect] reflect result $reflectresult"
  return $reflectresult
}

function clean_reflection() {
  # Reset
  logv "Cleaning up..."
  reflectorName
  reflectorId
  unset reflect
  return 0
}
