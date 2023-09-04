#!/bin/sh

set -ex

if VBoxManage modifyvm --help 2>&1 | grep -q -- --nat-localhostreachableN; then
  export ARCH_ANSIBLE_PACKER_VBOX_NAT_LOCALHOST_KEY="--nat-localhostreachable1"
  export ARCH_ANSIBLE_PACKER_VBOX_NAT_LOCALHOST_VAL="on"
else
  # Since the JSON is static, we must pass something valid into these vars
  # but it also has to be idempotent. Just restate that the first NIC is NAT.
  export ARCH_ANSIBLE_PACKER_VBOX_NAT_LOCALHOST_KEY="--nic1"
  export ARCH_ANSIBLE_PACKER_VBOX_NAT_LOCALHOST_VAL="nat"
fi

packer "$@"
