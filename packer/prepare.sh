#!/bin/sh

set -e

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

set_proxy
pacman -Syy --noconfirm --needed archlinux-keyring
pacman -S --noconfirm --needed ansible
unset_proxy
