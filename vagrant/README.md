# Arch-Vagrant

This project build on [Arch-Ansible](../README.md) to integrate it with
Vagrant, taking the official box `archlinux/archlinux` and provisioniing
it.  Due to some choices made by the base box maintainers, some aspects
are different with respect to an installation performed using
Arch-Anisble alone. For example, the base box uses GRUB instead of
Syslinux. However, if you need to rapidly spin up an Arch Linux box for
testing, these differences are likely to be of no concern.

Only VirtualBox is supported at this time.

The resulting installed system will be non-portable, meaning that proxy
settings and custom repositories will persist.

If working behind an HTTP(S) proxy, the `vagrant-proxyconf` plugin is
required. Conversely, `vagrant-vbguest` is disabled, becuase Arch ships
with its own guest additions packages.

Two variables can be tweaked in the `Vagrantfile`:

* `enable_audio` can be set to a supported (and system-specific) audio
  system recognized by VirtualBox, such as `pulse`. If so, the VM will
  have audio support, otherwise audio will be unavailable;
* `http_proxy` will  be passed to both `vagrant-proxyconf` and
  Arch-Ansible.

After optional tweaking, just spin your VM up with:

    vagrant up

<!-- vi: set tw=72 et sw=2 fo=tcroqan autoindent: -->
