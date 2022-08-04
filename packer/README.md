# Arch-Packer

This project builds on [Arch-Ansible](../README.md) to integrate it with
Packer, taking the official Arch Linux installation media and using it
to perform a full installation inside a VM.

Both VirtualBox and QEMU are supported at this time.

## Usage

If working behind an HTTP(S) proxy, the Packer variables `http_proxy`,
`https_proxy` and `no_proxy` can be specified and will be passed down to
Arch-Ansible. If not provided, they are read from the environment if
available.

The installation is portable, meaning that proxy settings and custom
repositories will not persist, but will be used just during the
installation.

To prepare VM images for all supported virtualization solutions, run:

```sh
packer build -parallel-builds=1 packer-template.json
```

The option `-parallel-builds=1` ensures that VMs are built in sequence.
This is necessary because two different hypervisors such as VirtualBox
and QEMU cannot use hardware acceleration at the same time.

If you need to build just one type of VM, you can specify the desired
builder on the command line:

```sh
# Only build a VirtualBox image
packer build -only=virtualbox-iso packer-template.json

# Only build a QEMU QCOW2 image
packer build -only=qemu packer-template.json
```

The output process produces either an OVF appliance for VirtualBox or a QCOW2
image for QEMU. For VirtualBox, the machine can be imported directly and will
retain its hardware configuration:

```sh
VBoxManage import --vsys 0 output-virtualbox-iso/*.ovf
```

For QEMU images, you only get the disk image, so it's important to
properly configure the VM to which the disk wil be attached. It is
recommended to select:

* `virtio` video;
* SPICE screen;
* at least 1 GiB of RAM;
* as many vCPUS as possible;
* the QEMU agent and SPICE channels to take
  advantage of better integration with the hypervisor.

## The insecure key

Packer connects to VMs via SSH and uses public key authentication. While
the `virtualbox-iso` builder generates an ephemeral key pair for that, the
`qemu` builder does not. Therefore, there is a key pair stored alongside the
template in `insecure_key{,.pub}` that is used during the
provisioning. Of course, the private part is not private at all since it's
stored unencrypted in the repo. The provisioning process takes care of
removing this key from the VM before exporting it, so that VMs created from
the image cannot be compromised using this key.

<!-- vi: set tw=72 et sw=2 fo=tcroqan autoindent: -->
