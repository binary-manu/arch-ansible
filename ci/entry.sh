#!/bin/sh

set -ex

if [ "$(ps --no-headers -p $$ -o euid -n)" -eq 0 ]; then
    rm -f /run/dbus/pid && dbus-daemon --system
    libvirtd --daemon
    virtlogd --daemon
    virsh net-create /etc/libvirt/qemu/networks/default.xml
    exec setpriv --clear-groups --reuid "$CI_UID" --regid "$CI_GID" "$0" "$@"
fi

HOME=/home/$CI_USER
cd
start-stop-daemon -b -m -p /tmp/pkgproxy.pid -O "$HOME/pkgproxy.log" -x "$PKGPROXY" -S -- -keep-cache
cp -v /config/.[a-z]* "$HOME/gh/"
exec "$@"
