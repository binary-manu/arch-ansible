#!/usr/bin/env bash

# NOTE: AI-generated from the old GH pipeline, with some
# manual tweaks.

#shellcheck disable=SC2091
#shellcheck disable=SC2206

set -euo pipefail

export ARCH_ANSIBLE_LIBVIRT_USER_SESSION=1
export ARCH_ANSIBLE_HEADLESS=1

FAST_FAIL=false
TESTS=(sp lvm btrfs uefi virtualbox libvirt)
DRY_RUN=false
CONFIGURATION_FILE="ansible/group_vars/all/90-ci-defaults.yaml"
CONFIGURATION='
 global_portable_image: true
 bluetooth_override: active
 xfce_user_customizations_kvantum_theme: KvAdaptaDark
 xscreensaver_override: active
 i3wm_enabled: true
 i3wm_screensaver_override: active
 i3wm_compositor_override: active
'

trap 'exit 1' TERM INT QUIT

usage() {
  echo "Usage: $0 [--fast-fail] [--tests='<space separated list of tests>']"
  echo "Valid tests: ${TESTS[*]}"
  exit 1
}

print_test() {
    local text="$1"
    echo "🧠 Running test ${text}"
}

print_red() {
    local text="$1"
    echo -e "❌ \e[31m${text}\e[0m"
}

print_green() {
    local text="$1"
    echo -e "✅ \e[32m${text}\e[0m"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --fast-fail)
      FAST_FAIL=true
      ;;
    --tests=*)
      TESTS=(${1#*=})
      ;;
    --debug-dry-run)
      DRY_RUN=true
      ;;
    *)
      usage
      ;;
  esac
  shift
done

ALL_OK=true

# Function to run install_media tests
run_install_media() {
  local config=(
    "sp disksetup/mbr_singlepart/ virtualbox-iso"
    "lvm disksetup/mbr_lvm/ qemu"
    "btrfs disksetup/bios_gpt_btrfs/ virtualbox-iso"
    "uefi disksetup/gpt_singlepart/ virtualbox-uefi"
  )

  for config_entry in "${config[@]}"; do
    local id disksetup provider
    read -r id disksetup provider <<< "$config_entry"

    if ! echo "${TESTS[@]}" | grep -qw "$id"; then
        continue
    fi

    print_test "$id"

    echo "disksetup_roles_prefix: $disksetup" > ansible/group_vars/all/91-ci-disksetup.yaml

    local res=0
    {
      cd packer
      rm -rf output-*
      if ! $DRY_RUN; then
        ./packer-wrapper.sh build -only="$provider" -timestamp-ui packer-template.json || res=$?
      fi
      rm -rf output-*
      cd -
    } &> "$LOGDIR/log-$id.log"

    if [ "$res" -ne 0 ]; then
      print_red "Test $id failed"
      if [ "$FAST_FAIL" = "true" ]; then
        echo "Fast fail triggered due to error in $id"
        exit 1
      fi
      ALL_OK=false
    else
      print_green "Test $id OK"
    fi
  done
}

# Function to run vagrant_provision tests
run_vagrant_provision() {
  local providers=("virtualbox" "libvirt")

  for provider in "${providers[@]}"; do
    if ! echo "${TESTS[@]}" | grep -qw "$provider"; then
        continue
    fi

    print_test "$provider"
    local res=0
    {
      cd vagrant
      vagrant destroy -f
      if ! $DRY_RUN; then
        vagrant up --provider "$provider" || res=$?
      fi
      vagrant destroy -f
      cd -
    } &> "$LOGDIR/log-$provider.log"

    if [ "$res" -ne 0 ]; then
      print_red "Test $provider failed"
      if [ "$FAST_FAIL" = true ]; then
        echo "Fast fail triggered due to error in $provider"
        exit 1
      fi
      ALL_OK=false
    else
      print_green "Test $provider OK"
    fi
  done
}

LOGDIR="$(dirname "$(realpath "$0")")"
cd "$LOGDIR/.."
rm -f "$LOGDIR"/log-*.log
echo "$CONFIGURATION" > "$CONFIGURATION_FILE"
run_install_media
run_vagrant_provision
$($ALL_OK)

# vi: set sw=2 ts=2 et autoindent :
