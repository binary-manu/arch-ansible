#!/bin/sh

HERE="$(realpath "$(dirname "$0")")"
HOMEDIR="$(realpath "$HERE/storage")"
IMAGE="ghcr.io/binary-manu/arch-ansible-ci:github"
ADD_CAPS="NET_ADMIN,NET_RAW"
HOSTNAME="linux-runner"
KEEP_SUP_GROUPS="--annotation=run.oci.keep_original_groups=1"

if [ -z "$FOREGROUND" ]; then
    FOREGROUND=-d
else
    FOREGROUND="--rm -it"
fi

podman run $FOREGROUND \
    --replace \
    --name ci \
    --hostname "$HOSTNAME" \
    -e PUID="$(id -u)" \
    -e PGID="$(id -g)" \
    --device=/dev/kvm:rw \
    --device=/dev/vboxdrv:rw \
    --device=/dev/vboxdrvu:rw \
    --device=/dev/vboxnetctl:rw \
    --device=/dev/net/tun:rw \
    --userns keep-id \
    --user root \
    --cap-add="$ADD_CAPS" \
    --security-opt=unmask=/proc/sys \
    -v "$HERE/config:/config" \
    -v "$HOMEDIR:/home" \
    $KEEP_SUP_GROUPS \
    "$IMAGE" "$@"
