# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For versions that have a major of 0, a convention is followed so that
the minor number is incremented when backward-incompatible changes are
made, while the third number is incremented for backward compatible
changes. For example, versions `0.2.x` are not compatible with `0.1.x`.

## [Unreleased]

## [0.3.6] - 2025-06-14

### Fixed

* VirtualBox machines use the `VBoxVGA` adapter again. There is
  currently an issue with Arch that causes Xorg to crash if `VMSVGA` is
  selected.
* Allow for longer timeouts when downloading from the AUR.

### Changed

* Change how X output names are looked up for XFCE settings: look for
  the first connected screen, even if it's not the primary one.
* Update the GH runner used for CI.

## [0.3.5] - 2025-05-04

### Fixed

* `pulseaudio` was not being installed.
* Xfce theme settings related to background images were broken, as
  recent Xfce versions changed the properties read to apply the
  background. This resulted in the default background being used instead
  of those provided by the themes.
* Vagrant base box switched to `boxen/archlinux-rolling`, as
  `archlinux/archlinux` seems to have vanished.
* The CI container was reworked to adapt to newer VirtualBox and
  libvirt. *IMPORTANT*: running it as an unprivileged user requires
  accessing `/dev/vboxdrv` as non-root, which is denied by the driver
  when it was compiled with hardening options.

### Added

* This release introduces multi DE/WM, adding i3 to the set of GUI
  environments that can be installed. Xfce4 remains the default, while
  i3 must be enabled explicitly.

  Since vanilla i3 is not really usable, there is no separation between
  plain i3 installation and it's theming, as had been done for Xfce:
  installing i3 also bring in application theming (GTK2/3/4 and Qt),
  some predefined keybindings and a bar configuration reporting CPU and
  memory usage, plus the clock.

  See the `i3wm` role and `i3wm_enabled` global option.
* Optionally, one can change the PAM system authentication configuration
  to tweak how errors from `pam_unix` are handled. The default scenario
  triggers `pam_faillock` even for unsuccessful login attempts that are
  not directly related to typing a bad password.

  A side effect of this is that, when using `xsecurelock`, when the
  prompt times out, that counts as a failed attempt, even if you didn't
  type anything. If you get into a situation where something triggers
  the prompt repeatedly, such as the mouse sending garbage, you'll find
  your account locked.

### Changed

* To support multi DE/WM, some parts of Xfce-related roles have been
  factored out for sharing. In particular, there is now a new `xinitrc`
  role responsible for creating `.xinitrc` in user homes.
* Eyecandy stuff has also been moved to `de_eyecandy`. This does mostly
  of what `xfce_user_customizations` used to do: installs themes and
  wallpapers and sets system-wide defaults for GTK/2/3/4 and Qt apps.
  `xfce_user_customizations` calls it to do the heavy lifting, and then
  copies Xfce-specific configuration files.
* The `users` role now patches `/etc/skel/.bashrc` so that, if the shell
  is run under a VTE terminal, such as Tilix, it sources appropriate
  profile files. This is a workaround to a performance isssue with
  Tilix, the default terminal under i3. The patch is applied
  unconditionally, since it only sources stuff when needed.

## [0.3.4] - 2025-02-05

### Changed

* The CI system now uses the latest official Packer, Vagrant and
  `vagrant-libvirt` rather than those coming with Debian 12.
* When provisioning Vagrant boxes using libvirt under user sessions,
  `9p` is used to mount shared folders. The CI system uses this kind of
  session and by default tries to use `virtiofs`, which is not supported
  in user mode by the libvirt shipped by Debian.

## [0.3.3] - 2024-09-22

### Changed

* The CI system has been switched from CircleCI to GitHub Actions. The
  CI container and workflows have thus been updated.

## [0.3.2] - 2024-05-06

### Fixed

* Update the boot command typed into UEFI VMs to start the system. The old
  command no longer boots the system, instead it remains stuck in edit mode,

## [0.3.1] - 2024-04-01

### Fixed

* Fix spots in the docs missed during the update for v0.3.0.
* Make the Vagrantfile work under Windows by not calling `grep` or other tools.
  To detect if VirtualBox needs additional tweaks depending on the help output,
  matching is now done in Ruby. Only `VBoxManage` needs to be in the path
  (under Windows you may need to add it manually).
* Explicitly set the Ansible configuration file in the Vagrantfile. This is a workaround
  for when the playbook is made available in the guest in a world-writeable folder:
  Ansible refuses to load configs from such dirs.

### Added

* Create a `packer-wrapper.ps1` script that works under Windows. It replaces
  `packer-wrapper.sh` on that OS.

## [0.3.0] - 2024-03-31

### Fixed

* When booting from the Arch Linux install media, wait for the system
  to settle before starting provisioning.
* For VirtualBox, detect if the installed version requires
  `--nat-localhostreachableN` in order to allow thw guest to access services on
  the host via NAT interfaces. In that case, add this option to the VM
  configuration.
* Ansible will now default to the latest version available, rather than sticking to
  version 7. Blocking bugs in Ansible have been fixed, so we can now go back to the
  latest version.

## Changed

* Due to Arch Linux shifting from SHA512 to YESCRYPT for password hashing, tasks
  which tried to increase the hashing rounds when generating password are now
  broken.  User-provided values (such as the default of 500000 rounds) are not
  applicable to YESCRYPT, and the current default load factor is probably sensible
  enough. Since YESCRYPT is deemed superior, I see no reason to keep SHA512-related
  stuff in the playbook.

  For this reasons:
  * `users_hash_rounds` and `users_override_passwd_hash_systemwide` have been removed.
    New passwords are generated using YESCRYPT with default parameters as defined by
    Arch itself.
  * The `sha512_hash` custom filter is no longer available, and `passlib` is no
    longer installed.
  * New users are created with a password of `*`, then updated via `chpasswd`.

  This is a breaking change, as it is no longer possible to rely on `passlib` and removed
  variables.

* To make the Packer template more flexible, some settings are now taken from
  environment variables.  A wrapper script `packer-wrapper.sh` is used to
  populate those variables before calling Packer. The wrapper shall be used in
  place of plain Packer and passes all command-line arguments down to Packer.
  Using the template directly without going through the wrapper is now
  unsupported. That is, if you used to run:

  ```sh
  packer build [options] packer-template.json
  ```

  you must now use:

  ```sh
  ./packer-wrapper.sh build [options] packer-template.json
  ```

  * Deprecated leftovers related to `mplugd` have been removed. This is a
  breaking change, since configurations still referring to these variables
  will stop working.


### Added

* Add a CircleCI-based container definition for testing the playbook. the container
  comes with VirtualBox, QEmu, libvirt, Packer and Vagrant and can work in rootless
  mode. It has only been tested with `podman`.
* Add an environment variable (`ARCH_ANSIBLE_HEADLESS`) to control if VMs should
  suppress their GUIs during provisioning or not. Defaults to false (GUIs will
  be shown by default, with the exception of libvirt). This is mainly used to suppress
  GUIs when running under CI.
* Add an environment variable (`ARCH_ANSIBLE_CPUS`) to control the number of CPUs
  used by VMs. Defaults to whatever applied before (1 for Packer, `nproc/2`
  for Vagrant). This is mainly used to adapt CPU usage to the CI runner.


## [0.2.14] - 2023-08-13

### Changed

* The deprecated `crypt` Python module has been replaced by `passlib`.
* Manually install `ansible` via `pip` in a virtual environment, and
  select a version that comes with `ansible-core` v2.14. v2.15 has
  introduced a breaking change, for which I have opened an
  [issue](https://github.com/ansible/ansible/issues/81500). Until I
  understand how to proceed (either the change is reverted or I need to
  update the playbook) I'll stick to `ansible-core` v2.14, which means
  `ansible` v7 branch. For Vagrant provisioning, the RAM size has been
  increased from 1024MiB to 1536MiB, to accomodate the virtual
  environemnt under `/tmp` and simplify clean-up.

### Fixed

* When provisioning Vagrant boxes, do not wait for `reflector` anymore.
* When using btrfs partitioning flows, enable `grub-btrfsd.service`
  instead of the old path unit.
* Fix the Packer boot command for the UEFI VM, since the boot
  script on the install media has changed.

## [0.2.13] - 2022-12-10

### Fixed

* Do not copy non-existent SSH host keys from the installation media.
  Use a wildcard-based approach instead.
* Fix a harmless error message in Packer boot commands if `/root/.ssh`
  already exists.

### Added

* Packer now provides a `virtualbox-uefi` builder, that can be used
  together with the `gpt_singlepart` partitioning flow to quickly create
  a 64-bit UEFI machine.

## [0.2.12] - 2022-10-29

### Fixed

* Packer now uses SHA256 digests, rather than MD5s, to validate ISO
  images.

## [0.2.11] - 2022-10-02

### Fixed

* Fix installation failure caused by a `pacman` package replacement prompt
  getting a `N` answer due to `--noconfirm`. It has been solved by simply postponing
  the installation of `xscreensaver` _after_ `xfce4`.

## [0.2.10] - 2022-09-07

### Fixed

* Replace Python's `random` module with `secrets` when generating password
  salts. This should produce a better random byte array using the most secure
  entropy source available on the system.

### Changed

* The ability to automatically install `mplugd` to handle guest screen
  autoresize in response to host window resize has been removed. `mplugd` is
  a Python 2 application, and due to the removal of some of its dependencies, it
  can no longer be installed from the mainstream repos. Despite this, guest
  autoresizing keeps working using a different approach, depending on the hypervisor:
    * for VirtualBox, switching the VGA adapter from `VBoxVGA` to `VMSVGA`, which is also
      the recommened value for Linux, causes it to work automatically as long as the
      guest additions are installed;
    * for QEMU/KVM, the job of `mplugd` has been moved to a script using `xev` and `xrandr`,
      which is launched alongside the GUI using a desktop entry.

  To summarize:
    * `mplugd` will no longer be available in new installations;
    * VirtualBox machines will now use the `VMSVGA` adapter, in place of `VBoxVGA`;
    * guest screen autoresizing will still work.

  Unless you used `mplugd` for anything else other than resizing the screen, or depended
  on the `VBoxVGA` adapter in some way, you should notice no issues with this new arrangment.
  Otherwise, you now where the issue tracker is!

## [0.2.9] - 2022-08-04

### Fixed

* Some dots in regular expessions were not escaped, matching any
  characters rather than just dots.
* Ensure that updates to `archlinux-keyring` are applied first than any
  other update, in case new keys have been added.
* Don't start the qemu guest agent during the installation, just enable it.
  This solves a provisioning issue with packer and qemu that caused the
  VM to fail, because the agent could not find the communication port to
  talk to the host.

### Added

* A new `kvantum` role is available to install and configure the Kvantum QT
  theme engine, in an attempt to select a QT theme that blends well with the GTK
  theme used by XFCE. Users of the stock XFCE DE should not call this role
  directly: instead, they should set `xfce_user_customizations_kvantum_theme` to
  the name of the Kvantum theme they want to use, such as `KvGnomeDark`.
* The `users` role have been improved to use more secure password hashing by
  default: it still uses SHA512 hashing as before, but now it is possible to set
  the number of rounds, instead of relying on the system default of 5000. The
  playbook's own default is 500000, which is still acceptable on modern or
  semi-modern hardware.  Also, the salt is generated randomly to be as long as
  possible given the limits of SHA512 hashing. All of this uses a new password
  generation filter instead of Ansible's `password_hash`, built on top of `random`
  and `crypt`.
* `users` can now also update relevant system files so that the selected number
  of rounds is also applied to passwords generated via `passwd`.

### Changed

* Packer now downloads an ISO image which does not contain the release date in
  the name. This solves the issue of failed Packer runs during the first days of
  the month if new monthly images haven't been published yet. It will just use the
  ISO from the previous month unless the new one appears.

## [0.2.8] - 2022-05-31

### Fixed

* When cleaning `yay` caches, ensure that the passwordless sudo user is
  employed rather than root.

## [0.2.7] - 2021-08-23

### Fixed

* Ansible `password_hash` filter no longer accepts integers as salt
  values.

### Changed

* `private_role_vars` is now enabled in the configuration file.

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
