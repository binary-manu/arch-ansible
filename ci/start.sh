#!/bin/sh

HERE="$(realpath "$(dirname "$0")")"
IMAGE="ghcr.io/binary-manu/arch-ansible-ci:github"
ADD_CAPS="NET_ADMIN,NET_RAW"
HOSTNAME="linux-runner"

if [ -z "$FOREGROUND" ]; then
    FOREGROUND=-d
else
    FOREGROUND="--rm -it"
fi

podman run $FOREGROUND \
    --replace \
    --name ci \
    --hostname "$HOSTNAME" \
    --device=/dev/kvm:rw \
    --device=/dev/vboxdrv:rw \
    --device=/dev/vboxdrvu:rw \
    --device=/dev/vboxnetctl:rw \
    --device=/dev/net/tun:rw \
    --cap-add="$ADD_CAPS" \
    --security-opt=unmask=/proc/sys \
    -v "$HERE/config:/config" \
    "$IMAGE" "$@"
