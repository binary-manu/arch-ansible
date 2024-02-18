#!/bin/sh

set -ex

if [ $(ps --no-headers -p $$ -o ruid -n) -eq 0 ]; then
    rm -f /run/dbus/pid && dbus-daemon --system
    libvirtd --daemon
    virsh net-create /etc/libvirt/qemu/networks/default.xml
    exec setpriv --keep-groups --reuid "$PUID" --regid "$PGID" "$0" "$@"
fi

cd
start-stop-daemon -S -b -m -p /tmp/pkgproxy.pid -x "$PKGPROXY" -keep-cache
exec "$@"
