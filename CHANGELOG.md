# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For versions that have a major of 0, a convention is followed so that
the minor number is incremented when backward-incompatible changes are
made, while the third number is incremented for backward compatible
changes. For example, versions `0.2.x` are not compatible with `0.1.x`.

## [Unreleased]

## [0.2.6] - 2021-03-31

### Fixed

* Fixed `pacman`/`yay` cache cleaning in role `clean`.
* Hardened uses of the `shell` and `command` modules by quoting all
  Jinja replacements.

## [0.2.5] - 2021-03-16

### Added

* Added a new partitioning flow: `bios_gpt_btrfs` for btrfs-on-root.

## [0.2.4] - 2021-03-03

### Added

* The playbook can now provision QEMU/KVM guests.
* Arch-Packer now supports the `qemu` builder.
* Arch-Vagrant now supports the `libvirt` provider.

### Changed

* Common values have been moved to variables within the `Vagrantfile` and
  the Packer template.

## [0.2.3] - 2021-01-20

### Changed

* Remove [saythanks.io](https://saythanks.io) badge.

### Fixed

* Update themes to track the Korla icon theme rename to Kora.

## [0.2.2] - 2020-12-01

### Added

* The Equilux theme has been integrated. It uses the Korla icon theme.
* The Dracula themes for GTK and icons have been integrated.
* The font `noto-fonts-emoji` is now installed by default, providing
  support for Unicode emojis.

### Changed

* The docs have been ported to GitHub pages using Jekyll. The README
  is now a much shorter "Getting started" introduction.

### Fixed

* Packer was unable to provision VM's because there was not enough space
  on archiso's rootfs to install Ansible. The Packer VM now uses 2GiB of
  memory and 1GiB of COW space to accomodate the tools.

## [0.2.1] - 2020-11-17

### Fixed

* Add `mode` to all `copy` and `template` tasks.

### Added

* Add some badges to the README, including a link to
  [saythanks.io](https://saythanks.io).

## [0.2.0] - 2020-06-25

### Changed

* `root` account information have been split from `users_info` into its
  own object `users_root_info`.
* `global_admins` has been deprecated. Now the list of users (for which
  personalizations are applied, such as setting the DE theme) is
  computed from the content of `users_info`: any key maps to a user. In
  order to make iterating over users easier, the `users` role provides a
  `users_names` list to module who depend on it.
* `global_passwordless_sudo_user` has been deprecated. Roles depending
  on this information should depend on the `passwordless_sudo_user` role
  and get it from `passwordless_sudo_user_name`.
* The `bootstrap` play have been revamped to support pluggable
  partitioning flows.
* Replaced most tags with variables that disable roles.
* `hostname` role variable `root` renamed to `chroot`.
* Documentation improvements.
* Default roles and collections path have been restricted to paths
  within the playbook itself.
* Default theme changed to darkblue.

These changes are not backward-compatible, as they break existing host
variable customizations or tag usage.

### Added

* Partitioning can be customized via _partitioning flows_,
  * Built-in single-partition MBR, GPT and LVM.
  * Write your own.
* Additional, third-party roles can be imported into the main
  configuration play to extend the installed system in flexible ways. It
  also works with roles and collections from Galaxy.
* Heavily improved `syslinux` role which can dinamically detect
  installed kernels and initramfs images, and generate appropriate
  bootloader entries. It will also discover device nodes to pass to the
  kernel as root or where to install things by looking at what is
  mounted at `/` and `/boot`.
* The wireless regulatory domain will be configured at install time.

## [0.1.8] - 2020-06-13

### Changed

* Replace deprecated Packer keyword `iso_checksum_url` with `iso_checksum`.

## [0.1.7] - 2020-05-02

### Added

* When installing under VirtualBox, it is possible to install and configure
  `mplugd` to handle screen resizing in place of `VBoxClient`. This is mainly intended
  to provide automatic screen resizing when using the `VBoxVGA` adapter instead
  of the recommended `VMSVGA`.

### Changed

* `linux-headers` no longer installed as part of VirtualBox guest support.

## [0.1.6] - 2020-04-30

### Added

* Multi-theme support. Different XFCE4 themes can be installed side by side.
  Other than the original Numix theme, a variant based on Numix-DarkBlue and the
  Korla icon theme, called `darkblue`, has been added. The
  `xfce_user_customizations` `defaults` file has been extended to allow
  specifying which themes are to be installed and which one is to be used as the
  default for created users.
* Bluetooth support. It is installed by default on bare metal installations
  and skipped in VM's. It can be enabled or disabled explicitly.
* Any modifications to the mirrorlist applied by adding or removing custom
  repos or mirrors will force a database sync.
* When provisioning Vagrant images, the preparation script will wait for reflector
  to update the mirrorlist.

### Fixed

* Fixed a bug in the `user_home` filter, which returned an exception rather
  than throwing it.
* Minor typos.

## [0.1.5] - 2019-10-07

### Changed

* Explicitly install packages that were included in the `base` group but have
  been left out from the dependencies of the `base` package.

## [0.1.4] - 2019-10-03

### Changed

* Packer template now uses generic URL's to reference the Arch Linux ISO and
  the checksum file. This eliminates the need for monthly updates to the
  template.
* References to home directories use the output of the `user` Ansible module
  rather than hardcoding the path to `/home/$USER`.
* Ansible is now installed explicitly in VM's provisioned with Arch-Vagrant,
  rather than via the auto-install feature of the `ansible_local` provisioner,
  which is broken in Vagrant 2.2.5.

### Fixed

* Add missing `xorg` dependency to role `xscreensaver`.
* Add missing dependency from `bootloader` to `base_packages`.
* Install the bootloader using the executable from the target chroot,
  not the one from the installation media.

## [0.1.3] - 2019-09-07

### Fixed

* VM's created via Packer will set the RTC to UTC time.

### Added

* Users can be created with additional groups.
* Users may be restricted from calling sudo.
* Add xscreensaver in place of xfce4-screensaver. It is configured with a
  timeout of 5 minutes for bare metal installations, while VM installations
  have no screensaver/screen lock by default, assuming that the host will do
  that. This can be overridden.
* Add pkgproxy integration giude
* Add bare metal install guide

### Changed

* Arch-Packer now uses Arch Linux ISO 2019-09-01.

## [0.1.2] - 2019-08-04

### Fixed

* The Numix theme is now installed from `numix-gtk-theme-git` rather than the
  now unavailable `numix-gtk-theme`.
* Fix typos in the READMEs.
* Remove non-existant font package `ttf-freefont`.

### Changed

* Arch-Packer now uses Arch Linux ISO 2019-08-01.

## [0.1.1] - 2019-06-24

### Fixed

* Various typos in the READMEs.
* `memdisk` is copied alongside all other Syslinux modules.
* Comments from `pacman.conf` that were wrongly stripped off during the
  provisioning are now kept.

## [0.1.0] - 2019-06-15

### Added

* Initial release of the playbook.
* Initial release of the Arch-Vagrant side project.
* Initial release of the Arch-Packer side project.

<!-- vi: set tw=72 et sw=2 fo=tcroqan autoindent: -->
