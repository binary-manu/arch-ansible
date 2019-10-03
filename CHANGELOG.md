# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
