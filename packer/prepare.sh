#!/bin/sh

set -ex

ANSIBLE_VENV=/tmp/ansible_venv

set_proxy() {
    if [ -n "$http_proxy" ]; then
        sed --in-place -e 's|^#\(XferCommand = /usr/bin/curl.*\)$|\1|' /etc/pacman.conf
    fi
}

unset_proxy() {
    if [ -n "$http_proxy" ]; then
        sed --in-place -e 's|^\(XferCommand = /usr/bin/curl.*\)$|#\1|' /etc/pacman.conf
    fi
}

systemctl is-system-running --wait
set_proxy
pacman -Syy --noconfirm --needed archlinux-keyring
pacman -S --noconfirm --needed python-pip
python -m venv "$ANSIBLE_VENV"
"$ANSIBLE_VENV/bin/pip" install ansible passlib
unset_proxy
