# Arch-Packer

This project build on [Arch-Ansible](../README.md) to integrate it with
Packer, taking the official Arch Linux installation media and using it
to perform a full installation inside a VM.

Only VirtualBox is supported at this time.

If working behind an HTTP(S) proxy, the Packer variables `http_proxy`,
`https_proxy` and `no_proxy` can be specified and will be passed down to
Arch-Ansible. If not provided, they are read from the environment if
available.

The installation is portable, meaning that proxy settings and custom
repositories will not persist, but will be used just during the
installation.

To prepare the VM image:

    packer build packer-template.json

<!-- vi: set tw=72 et sw=2 fo=tcroqan autoindent: -->
