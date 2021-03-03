# Arch-Vagrant

This project builds on [Arch-Ansible](../README.md) to integrate it with
Vagrant, taking the official box `archlinux/archlinux` and provisioning
it.  Due to some choices made by the base box maintainers, some aspects
are different with respect to an installation performed using
Arch-Ansible alone. For example, the base box uses GRUB while many
partitioning flows opt for Syslinux. However, if you need to rapidly
spin up an Arch Linux box for testing, these differences are likely to
be of no concern.

Both VirtualBox and QEMU (via libvirt) are supported and the official
base box provides support for both.

The resulting installed system will be non-portable, meaning that proxy
settings and custom repositories will persist.

If working behind an HTTP(S) proxy, the `vagrant-proxyconf` plugin is
required. Conversely, `vagrant-vbguest` is disabled, because Arch ships
with its own guest additions packages.

The following variables can be tweaked in the Vagrantfile:

* `enable_audio` can be set to a supported (and system-specific) audio
  system recognized by VirtualBox, such as `pulse`. If so, the VM will
  have audio support, otherwise audio will be unavailable. This setting
  has no effect for libvirt machines, which always have audio support;
* `http_proxy` will  be passed to both `vagrant-proxyconf` and
  Arch-Ansible. Set it when wotking behind an HTTP proxy;
* `default_memory` is the amount of RAM the VM will get, in MiB;
* `default_video_ram` is the amount of video RAM the VM will get, in
  MiB;
* `default_cpus` is the number of virtual CPUs the VM will get. By
  default, it is set to half the logical processor of the host, so if
  you have a 12-thread CPU it will be set to 6.

Please note that RAM settings are usually adequate for booting and
provisioning the VM and to allow the final system to start the GUI.  You
may need to increase them to open many apps or if you customize the
playbook to install a heavier DE.

When audio is enabled (which means always for libvirt machines) the
emulated audio is AC97 and there is currently no way to change that but
manually editing the Vagrantfile.

libvirt machines use the `virtio` GPU and have the SPICE and QEMU
agent channels enabled by default.

After optional tweaking, just spin your VM up with:

    vagrant up --provider=$PROVIDER

`$PROVIDER` is simply a placeholder and should be set appropriately to
select either `virtualbox` or `libvirt`. The latter should be chosen to
run VMs backed by QEMU.

After provisioning is complete, restart the VM. This is a required step
to load a new kernel in case one was installed, as well as to hand over
network management from systemd-networkd to NetworkManager.

    vagrant reload

<!-- vi: set tw=72 et sw=2 fo=tcroqan autoindent: -->
