#!/bin/sh

set -ex

if [ "$(ps --no-headers -p $$ -o euid -n)" -eq 0 ]; then
    if [ -z "$PUID" -o -z "$PGID" ]; then
        echo "PUID and PGID need to be defined" >&2
        exit 1
    fi
    rm -f /run/dbus/pid && dbus-daemon --system
    libvirtd --daemon
    virsh net-create /etc/libvirt/qemu/networks/default.xml
    exec setpriv --keep-groups --reuid "$PUID" --regid "$PGID" "$0" "$@"
fi

cd
start-stop-daemon -b -m -p /tmp/pkgproxy.pid -O "$HOME/pkgproxy.log" -x "$PKGPROXY" -S -- -keep-cache
cp -v /config/.[a-z]* /opt/gh/
exec "$@"
