#!/bin/sh

# If the proxy has been provisioned, change pacman's transfer command to curl
if [ -n "$http_proxy" ]; then
    sed --in-place -e 's|^#\(XferCommand = /usr/bin/curl.*\)$|\1|' /etc/pacman.conf
fi

# Perform a full system update. This is required by both arch-ansible (because
# the configuration steps assume that pacstrap synced the indices) and by the
# ansible_local provisioner (which updates the indices and installs Ansible,
# but does not perform a full update so we may end up with a broken apartially
# updated system).
# It also installs the following packages because, again, the bootstrap phase
# of arch-ansible would have done that:
#   - base-devel
#   - networkmanager
pacman -Syu --noconfirm --needed base-devel networkmanager

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
