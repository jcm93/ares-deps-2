#!/usr/bin/env bash

set -euo pipefail

build_deps() {
  os=''
  check_os os
  
  arch=''
  check_architecture arch
  
  config="${1-RelWithDebInfo}"
  
  # where are we?
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  
  # add utils scripts for our platform to this file
  utils_folder="$SCRIPT_DIR/utils.$os"
  for util in "$utils_folder"/*
  do
    if [ ! -d "$util" ]; then
      source "$util"
    fi
  done
  
  # add all dependency script files for our platform to this file
  deps_folder="$SCRIPT_DIR/deps.$os"
  echo $deps_folder
  dependencies=()
  for dependency in "$deps_folder"/*
  do
    if [ ! -d "$dependency" ]; then
      source "$dependency"
      dependencies+=("$(basename "$dependency")")
    fi
  done
  
  mkdir -p "build_temp"
  cd "build_temp"
  for dependency in "${dependencies[@]}"
  do
    # set up the dependency
    setup_func="${dependency}_setup"
    $setup_func
    
    # if we have a patch, patch the dependency
    patch_func="${dependency}_patch"
    $patch_func
    
    # build the dependency
    build_func="${dependency}_build"
    $build_func
  done
  cd ..
  
  mkdir -p "ares-deps"
  for dependency in "${dependencies[@]}"
  do
    # install the dependency
    install_func="${dependency}_install"
    $install_func
  done
  cd ..
  echo "artifactName=ares-deps-$os-$arch" >> $GITHUB_OUTPUT
}

check_os() {
  if [ "$(uname)" == "Darwin" ]; then
    eval "$1='macos'"
  elif [ "$(uname)" == "Linux" ]; then
    eval "$1='linux'"
  else
    eval "$1='windows'"
  fi
}

check_architecture() {
  if [ "$(uname)" == "Darwin" ]; then
    eval "$1='universal'"
  elif [ "$(uname)" == "Linux" ]; then
    eval "$1='universal'"
  else
    local unametest=$(uname -a)
    echo $unametest
    local unameout=$(uname -p)
    eval "$1=$unameout"
  fi
}

build_deps "${@}"
