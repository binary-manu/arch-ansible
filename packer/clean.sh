#!/bin/sh

set -e

pacman -Rs --noconfirm ansible
rm -rf /root/.ansible

# Packer's QEMU builder seems to fail to remove the SSH key
# even when ssh_clear_authorized_keys is true. And virtualbox-iso
# always tries to remove it even when ssh_clear_authorized_keys is
# false and if the file does not exist it prints errors.
# To make everyone happy, we remove the keys here but keep the empty
# file around.
truncate -s 0 /root/.ssh/authorized_keys
