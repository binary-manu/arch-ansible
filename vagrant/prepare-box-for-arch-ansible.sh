#!/bin/sh

set -e

# These packages are no longer pulled in by the "base" package. So we install
# them explicitly. `base` is present because the initial Vagrant image may
# still be based on the group rather than on the package.
EXTRA_BASE_PACKAGES="
    base
    cryptsetup
    device-mapper
    dhcpcd
    e2fsprogs
    inetutils
    jfsutils
    linux
    linux-firmware
    logrotate
    lvm2
    man-db
    man-pages
    mdadm
    nano
    netctl
    perl
    sysfsutils
    texinfo
    usbutils
    vi
    xfsprogs
"

# If the proxy has been provisioned, change pacman's transfer command to curl
if [ -n "$http_proxy" ]; then
    sed --in-place -e 's|^#\(XferCommand = /usr/bin/curl.*\)$|\1|' /etc/pacman.conf
fi

# The base Vagrant image uses reflector to generate a new mirrorlist
# on the first boot. This means we must wait for it to finish before
# upgrading the system.
systemctl start reflector-init

# Perform a full system update. This is required by arch-ansible, because the
# configuration steps assume that pacstrap synced the indices. It also
# installs some packages because, again, the bootstrap phase of arch-ansible
# would have done that. Ansible is installed here because Vagrant 2.2.5 fails
# to install it.
pacman -Syy --noconfirm --needed archlinux-keyring
pacman -Su --noconfirm --needed base-devel networkmanager ansible \
    $EXTRA_BASE_PACKAGES

# Replace systemd-networkd with NetworkManager
# The actual service swap happens at the next reboot
systemctl enable NetworkManager.service
systemctl disable systemd-networkd.service

# Remove packages that will conflict with arch-ansible. It currently expects to
# be able to install VirtualBox guest additions with GUI support, but they
# conflict with the -nox package which comes with the box.
if pacman -Qi virtualbox-guest-utils-nox > /dev/null 2>&1; then
    pacman -Rs --noconfirm virtualbox-guest-utils-nox
fi
