#!/bin/sh

# If the proxy has been provisioned, change pacman's transfer command to curl
if [ -n "$http_proxy" ]; then
    sed --in-place -e 's|^#\(XferCommand = /usr/bin/curl.*\)$|\1|' /etc/pacman.conf
fi

# Perform a full system update. This is required by arch-ansible, because the
# configuration steps assume that pacstrap synced the indices). It also
# installs some packages because, again, the bootstrap phase of arch-ansible
# would have done that. Ansible is installed here because Vagrant 2.2.5 fails
# to install it.
pacman -Syu --noconfirm --needed base-devel networkmanager ansible

# Enable and start NetworkManager, while removing systemd-netword profiles.
systemctl enable NetworkManager.service
systemctl start  NetworkManager.service
rm -f /etc/systemd/network/eth0.network

# Remove packages that will conflict with arch-ansible. It currently expects to
# be able to install VirtualBox guest additions with GUI support, but they
# conflict with the -nox package which comes with the box.
if pacman -Qi virtualbox-guest-utils-nox > /dev/null 2>&1; then
    pacman -Rs --noconfirm virtualbox-guest-utils-nox
fi
