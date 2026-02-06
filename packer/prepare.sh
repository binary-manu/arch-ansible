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
pacman -Syy --noconfirm --needed --ask=6 archlinux-keyring
pacman -S --noconfirm --needed --ask=6 python-pip
python -m venv "$ANSIBLE_VENV"
"$ANSIBLE_VENV/bin/pip" install ansible
unset_proxy
