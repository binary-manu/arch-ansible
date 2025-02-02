#!/bin/sh

HERE="$(realpath "$(dirname "$0")")"
IMAGE="ghcr.io/binary-manu/arch-ansible-ci:github"
ADD_CAPS="NET_ADMIN,NET_RAW"
HOSTNAME="linux-runner"
KEEP_SUP_GROUPS="--annotation=run.oci.keep_original_groups=1"
CI_UID=1000
CI_GID=1000

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
    --userns keep-id:uid=$CI_GID,gid=$CI_GID \
    --user root \
    --cap-add="$ADD_CAPS" \
    --security-opt=unmask=/proc/sys \
    -v "$HERE/config:/config" \
    $KEEP_SUP_GROUPS \
    "$IMAGE" "$@"
