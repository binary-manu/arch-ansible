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

## Why VM preparation fails at the start of the month?

Arch Linux installation media are released monthly, at the beginning of the
month and their URLs contain the year and month of the release, for example:

    http://mirror.rackspace.com/archlinux/iso/latest/archlinux-2021.02.01-x86_64.iso

The Packer template uses a parameterized URL to always download the most
recent ISO, and uses today's date to obtain the year and the month (the day
is always `01`). This means that, as soon as the system clock moves to the midnight
of the first day of a new month, the URL changes. If the upstream mirror does not yet
provide a copy of the new ISO image, Packer will fail because it cannot download the
installation media.

This issue goes away in a few hours as the mirror is updated. Meanwhile, you
can simply edit the template and replace the parametric URL with a fixed one,
pointing to the previous ISO:

```diff
diff --git a/packer/packer-template.json b/packer/packer-template.json
index bbd4f45..235df1e 100644
--- a/packer/packer-template.json
+++ b/packer/packer-template.json
@@ -3,8 +3,8 @@
     "http_proxy"  : "{{env `http_proxy`}}",
     "https_proxy" : "{{env `https_proxy`}}",
     "no_proxy"    : "{{env `no_proxy`}}",
-    "arch_iso"    : "http://mirror.rackspace.com/archlinux/iso/latest/archlinux-{{isotime \"2006.01\"}}.01-x86_64.iso",
-    "arch_iso_sum": "file:http://mirror.rackspace.com/archlinux/iso/latest/md5sums.txt",
+    "arch_iso"    : "http://mirror.rackspace.com/archlinux/iso/2021.02.01/archlinux-2021.02.01-x86_64.iso",
+    "arch_iso_sum": "file:http://mirror.rackspace.com/archlinux/iso/2021.02.01/md5sums.txt",
     "ssh_authkey" : "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMxWY/8/m23+oBuOdC8YH7SdhaRdTQ0fRqcL8O3EaIUX TempKey",
     "cmd_cow"     : "<tab><end> cow_spacesize=1G<enter>",
     "cmd_ssh"     : "<wait60>systemctl start sshd && mkdir -m 0700 /root/.ssh<enter>",,
```

<!-- vi: set tw=72 et sw=2 fo=tcroqan autoindent: -->
