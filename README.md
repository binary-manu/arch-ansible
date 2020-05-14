# Arch-Ansible: an Ansible playbook to install Arch Linux

![Screenshot of the Numix theme][numix]

![Screenshot of the DarkBlue theme][darkblue]

Arch-Ansible is a playbook designed to install Arch Linux on a target
machine. It was conceived to ease the preparation of virtual machines,
but it can also be used to install on bare metal.

## Ansible version

The playbook has been tested using Ansible 2.7 and higher.

## Migrating to a non-backward-compatible playbook version

### 0.1.x ➔ 0.2.x

#### Passwordless-`sudo`-enabled user

`global_passwordless_sudo_user` has been deprecated. Roles that need it
should depend on the `passwordless_sudo_user` role and get it from
`passwordless_sudo_user_name`.

#### Changes to user management

User account information has been harmonized, eliminating some unused
objects and splitting root info from the rest of the users, since most
attributes do not make sense for root.

If you have an existing configuration made of host/group variables you
wish to migrate:

* delete the now deprecated `global_admins`;
* move the contents of `root` from `users_info` to `users_root_info`:

  ```yaml
  # Go from this:
  users_info:
    root:
      XXX
    other_user:
      YYY

  # to this:
  users_info:
    other_user:
      YYY

  users_root_info:
    XXX
  ```

All modules that want to iterate over users should replace
`global_admins` with `users_names`. They should also depend on `users`.
The contents of `users_names` are generated from `users_info`, which
removes the need to keep the user name list and the user information
strcture in sync, as in the previous branch.

More on this role in [users](#users).

#### Changes to partitioning

The partitioning phase has been reworked to allow for more flexible
partitioning and bootloader installation, including the case of users
dropping their own partitioning roles to automate specific deployments
without the need to fork and customize.

More info can be found in the [bootstrap](#bootstrap),
[partitioning](#partitioning) and [partitioning
flows](#Partitioning-flows) sections.

The `mbr_singlepart` partitioning flow produces exactly the same results
as the previous branch.

#### Changes to tags

Most tags have been eliminated because they provided little value. Refer
to [this section](#Tags) for a list of supported tags and their intended
usage.

## Installed system

Unless some steps are skipped or customized, the installed system will
run XFCE with the Numix theme. No greeter is installed by default: each
user's `.xinitrc` is configured to launch XFCE when calling `startx`.
An alternative, darker style based on the Numix-DarkBlue theme is
available.

The `xfce4-screensaver` package is ditched in favor of `xscreensaver`.
By default, systems installed in VM's will have it disabled, since I
would assume that the host already has a screensaver/lock. Bare metal
installations, conversely, have it enabled by default to power off the
screen after a few minutes. It is possible to override this behaviour.

Optional Bluetooth support can be installed. By default it is only
installed on bare-metal installations. This behaviour can be overridden
(i.e. to test a Bluetooth dongle in a VM via USB passthrough).

A bunch of default utilities like a PDF reader or gvim a preinstalled.
These are handled by the `utils` and `xutils` roles.

Users (including `root`) get their passwords from
`roles/users/defaults/main.yaml`.

The predefined partitioning flow defines a single-partition MBR layout,
using Syslinux as the bootloader installed on root. Swap space is not
configured.  Alternative flows are defined, including:

* support for root on LVM, under a MBR table;
* support for EFI installation.

Flows are designed to operate on whole disks: they take an empty disk,
partition it, and create filesystems. This is good for VM provisioning,
which start with pristine disks) or bare metal installations performed
on empty disks. For more complex scenarios (such as bare metal
installations where partitioning needs to be reconfigured to accomodate
Arch Linux in dual boot) one can either disable automatic partitioning
and do it manually or define a custom flow. The latter requires writing
a bunch of Ansible roles.

There is support for installing hypervisor guest additions as part of
the process, altought it can be disabled. As of today, only VirtualBox
is supported.

The playbook relies on the [Yay](https://github.com/Jguer/yay) AUR
helper to install packages. Using `yay` instead of the stock `pacman`
module allows for uniform installation of binary and AUR packages. You
are free to uninstall `yay` after the provisioning is complete and to
install your favorite AUR helper.

## Partitioning flows

One the biggest limitations if branch `v0.1.x` was that the partitioning
performed by `bootstrap` phase was inflexible. You only got MBR-style
partition tables, single root layouts with ext4 and Syslinux as the
bootloader. The IPL code in the MBR was also overwritten at install
time.

While that setup is fine for some scenarios, specifically VM
provisioning, when the disk is always fresh, it can be unsuitable when
provisioning bare metal systems with other partitions an OSes in place.

To circumvent the problem, the fixed roles that implemented partitioning
have been replaced with the concept of a _partitioning flow_. A
partitioning flow is a collection of roles, each one taking care of a
specific step of partitiong, which are called by the `bootstrap` phase
at appropriate times. These role a bundled together into a _base
folder_, and that folder is placed somewhere where Ansible can find
roles. At that point, a variable is used to specify the base folder
name, and the roles beneath it will be used at install time.

This way, each partitioning flow can be seen as a plugin, providing
pre-canned partitioning scheme for different scenarios (i.e. RAID, LVM,
GPT, MBR, different filesystems for root, multipartition layouts and so
on).

Writing a new partitioning flow requires wrinting some Ansible roles.
For repetitive tasks this can be a good idea. For one-shot setups, one
may be found [manual partitioning](#Manual-partitioning) a faster
approach.

### Built-in flows

Currently, this playbook come with a bunch of ready-made flows that
cover some basic scanrios and are mostly useful for VM provisioning:

* `partitioning/mbr_singlepart`: a single disk is formatted with a
  single, large root partition using a MBR partition table. The
  partition will use 32-bit ext4 (required for Syslinux to work) and
  Syslinux as the bootloader.  The IPL of that disk will be replaced to
  load Syslinux at boot;
* `partitioning/gpt_singlepart`: a single disk is formatted with two GPT
  partitions, a large root partition plus an ESP. The root partition
  will use 64-bit ext4 and GRUB2 as the bootloader. The size of the ESP
  can be adjusted and defaults to 512MiB;
* `partitioning/mbr_lvm`: a single disk is formatted with two MBR
  partitions, a large LVM partition plus a small primary boot partition.
  The LVM partition is used to create a PV and a VG which will then host
  the root LV, ext4-formatted. The boot partition will hold the kernels
  for the non-LVM-aware bootloader. Syslinux is used to boot up. The
  size of the boot partition can be configured and defaults to 512MiB.
  Don't make it too small if you want to install additional kernels.

### Flow structure and location

Partitioning flows must reside under a path that Ansible uses when
searching for roles. By default, the playbook restricts those paths to:

* `$ARCH_ANSIBLE_ROOT/ansible/roles` where built-in roles reside. All
  built-in flows are grouped under `partitioning`, that why you need to
  refer to them as `partitioning/$FLOW_NAME`, such as
  `partitioning/mbr_lvm`;
* `$ARCH_ANSIBLE_ROOT/ansible/extra_roles` is meant to store third-party
  flows, so that they don't mess up with built-in stuff.

For example, if you place your new flow `foopart` under
`$ARCH_ANSIBLE_ROOT/ansible/extra_roles`, your roles will reside at
`$ARCH_ANSIBLE_ROOT/ansible/extra_roles/foopart`, it base folder.

Each base folder contains one subfolder per role, and each flow is
composed of exactly 3 roles:

* `partitioning`: this is called _before_ the base system is installed.
  It is meant to prepare and mount the partitions for the target
  systems, so that base package installation can use them. This role
  does things like defining partitions, formatting them, and mounting
  them;
* `postpartitioning`: is run _after_ the base packages have been
  installed. This means it can assume a standard filesystem hierarchy
  being present on the new root, including standard Arch tools and
  configuration files. This is the place where things like generating
  the fstab or tweaking the initcpios are done;
* `bootloader`: is run last to install and configure the bootloader.

Bootloader installation is considered part of partitioning, simply
because some partitioning choice may rule out certain bootloaders or
require special installation options.

When implementing a role, feel free to call on other built-in modules to
save some coding. Roles such as `genfstab` and `syslinux` are there to
be used . For example, if you `bootloader` role can simply delegate
everything to `syslinux`, just make it an empty role with a dependency
on `syslinux`.

A typical flow tree structure is as follows:

    mbr_lvm/
    ├── bootloader
    │   └── meta
    │       └── main.yaml
    ├── partitioning
    │   └── tasks
    │       ├── defaults.yaml
    │       └── main.yaml
    └── postpartitioning
        ├── meta
        │   └── main.yaml
        └── tasks
            └── main.yaml

Have a look at built-in flows for an example.

### Flow interfaces

Each flow roles may need to pass information to other parts of the
playbook, both to roles in the same flow and to built-in roles. To make
this easier while avoiding conflicts, a simple naming scheme is defined
for such information. In general, each role provides information to
other roles by means of facts, which can be set using the standard
`set_fact` module.

#### Interface towards other flow roles

If a flow role needs to define a fact to be consumed by a role in the
same flow that is called later (i.e. pass data from `partitioning` to
`bootloader`, for example), that fact should follow the convention that
its name looks like:

    partitioning_priv_*

For example, `partitioning_priv_root_devnode` can store the device node
used for the root partition, which is established at `partitioning` time
and later used to install the bootloader. Apart from the prefix,
flow-local fact names are arbitrary.

#### Interface towards the rest of the playbook

At present time, the only expectation the rest of the playbook places on
paartitioning flows is that the `partitioning` role should define where
the root partition (and all other partitions mounted below it) is
mounted, by defining the `partitioning_root_mount_point` fact.

Often, one will simply use `/mnt` is the root mountpoint, so it will use
something like this to make this information available:

```yaml
- name: Define public interface facts
  set_fact:
    partitioning_root_mount_point: /mnt
```

## Playbook structure

The playbook is broken into two big parts, identified by tags:

* `bootstrap` is meant to run against a system running an Arch Linux
  installation media. It takes care of partitioning the disk, installing
  a bootloader and a set of base packages. Then reboot.
* `mainconfig` runs against the installed base system, adding additional
  packages, installing a DE, creating users and configuring locales. At
  the end, the system is ready for use.

When used together, they build a complete system from an installation
media. `mainconfig` can also be run independently of `bootstrap`,
provided that the initial system state allows for Ansible incoming
connections.

This scenario could be used to provision an existing Vagrant box, for
which `bootstrap` would be of no use, since it is already partitioned
and base packages are installed. Some minor adjustments might be
required in this case (i.e. Vagrant boxes likely come with pre-installed
VirtualBox guest utilities without X support, which will cause
`virtualbox-guest-utils` not to install).

### bootstrap

The `bootstrap` phase encompasses the following stages:

* partitioning: disks are partitioned and partitions are formatted and
  then
  mounted for later use;
* base package are installed to the target system;
* post-partitioning: tasks which are related to partitioning but can
  only be performed after the basic filesystem hierarchy is in place;
  this is where one would add entries to `/etc/fstab` or add hooks to
  `/etc/mkinitcpio.conf`;
* the bootloader is installed to the target system.

By design, bootloader installation is considered a part of partitioning.
This is because one cannot choose a bootloader independently of the
partitioning scheme: for example, Extlinux cannot be installed on 64-bit
ext4, which must be taken into account when creating the `/boot`
filesystem. Therefore, if partitioning is skipped, bootloader
installation is also skipped.

Installation of base packages cannot be skipped, but it can be
customized by editing `roles/base_packages/defaults/main.yaml`. It
already contains a very minimal set of packages and there is no
advantage is adding additional tools here.

Partitioning, post-partitioning and bootloader installation can be
customized in 3 major ways:

* they can be disabled. This is useful when total control over
  partitioning is desired: the user first performs partitioning
  manually, then runs the `bootstrap` phase with partitioning disabled,
  so that base packages are installed. Then it manually installs its
  bootloader of choice. At this point, it can run the `mainconfig`
  phase;
* they can be switched by choosing a different built-in flow. A global
  setting controls which partitioning flow is used, and arch-ansible
  comes with a few of them that cover the most basic scenarios;
* they can be implemented by the user. The same setting that selects a
  built-in flow can be used to select user-provided flows. Flows are
  simply a collection of related Ansible roles which take care of
  partitioning and expose a well-defined interface to the other roles,
  for example, to let them now where partitions are mounted. This way,
  users can add their own specific partitioning logic to the playbook
  without the need to fork and edit the core roles and plays. _Note
  that, while approach should give enough flexibility for many
  scenarios, extreme configurability may still require modifications to
  the core components and thus a fork_.

By default, this phase is disabled. To run it, add the `bootstrap` tag
to the call.

### mainconfig

The `mainconfig` tag marks the tasks that does the heavy lifting. It
configures locales, creates users, sets their initial passwords, and
prepare the system to work behind a proxy. Additional steps include
installing utilities and GUI apps, a desktop environment and applying
default customizations to users.

Roles which install X apps will automatically pull X.org as a
dependency.

### Reboot

After both `bootstrap` and `mainconfig` the system will be rebooted to
ensure a clean start. This can be disabled by skipping the `reboot` tag.

### Force handlers to run again

If during execution, the playbook fails while executing a handler, the
next time it runs the handler will not run again, because the notifying
task will report an `ok` status.

As a workaround, you can force all handlers to run again by setting the
variable `run_handlers` to `true`. This works by causing all tasks that
trigger a handler to report a `changed` status.

It works differently than `--force-handlers`. As per Ansible
documentation:

> When handlers are forced, they will run when notified even if a task
> fails on that host.

While, in our scenario, handlers would _not_ be notified by tasks when
they return `ok`.

## Configuration

By design, global configuration items are those which are used by
multiple roles and are stored in `group_vars/all/00-defaults.yaml`.
Other variables, which are local to a specific role, are stored under
either:

* `roles/$ROLE/defaults/main.yaml`, or
* `roles/$ROLE/tasks/defaults.yaml`.

The second form is used for partitioning roles, which need to make
variables available as facts to other roles invoked as part of the
same partitioning flow. The main difference between the two forms is
the use of `set_fact` in the latter.

Both groups can be overridden by placing a new file under `group_vars`,
`host_vars` or using the command line. This way, one can keep the
default configuration and just change the target system hostname or
locale.

Global and role-local configuration variables are documented in detail
inline in the YAML files themselves. The following sections give an
overview of the high-level concepts behind them.

### Global configuration

#### Partitioning flow

    global_partitioning_role: partitioning/mbr_singlepart

If the `bootstrap` phase is executed, it will need to enact a
partitioning flow. Which flow is run is determined by the value of the
variable above.

#### Portable image

    global_portable_image: False

This variable controls whether the resulting installation should be
site-independent or not. If set to false, the playbook assumes that
settings such as custom repos and proxy configuration must persist in
the installed system. If set to true, such settings will be reverted in
the final setup.

This is useful, for example, if the installation process requires using
an HTTP proxy, but the system is then going to be moved to a different
network where a proxy is not needed. A typical case is provisioning a VM
image with Packer from behind a proxy: the final image should not carry
such site-specific proxy settings if it is going to be shared with a
wider audience.

These are the installation elements affected by this flag:

* HTTP proxy settings: they will be evicted from the final system and
  all customization needed to use them effectively (such as `sudoers`
  tweaks preserving them across calls to `sudo`, shell profiles adding
  them to the environment, …) will be undone;
* custom repositories and mirrors: they are removed from
  `/etc/pacman.conf`.

#### Proxy setup

If working behind a (HTTP(S)) proxy, add appropriate definitions for

* `http_proxy`
* `https_proxy`
* `no_proxy`

This will automatically trigger proxy-related tasks and configure the
installed system to work behind a proxy (by setting appropriate
environment variables).

#### Tags

The following tags can be used to enable or disable specific parts of
the playbook:

* `bootstrap`: enables or disables the whole bootstrap phase, which runs
  against the Arch installation media. It is disabled by default,
  because the bootstrap phase performs potentially dangerous operations
  like partitioning and formatting. Keep disabled when provisioning
  ready-made base systems like Vagrant images. Enable when provisioning
  bare metal systems or Packer VM's;
* `mainconfig`: disables or enables the entire mainconfig phase. This is
  run by default, and there is probably no reason to skip it unless you
  are debugging bootstrap;
* `reboot`: skip it to disable reboots at certain points of the
  installation.  Useful if the reboot should be avoided: the Packer
  template provided with [arch-packer](packer/README.md) is an example
  of this;
* `virtguest`: disable tasks that would install hypervisor-specific
  packages or configure things. They are already skipped automatically
  when the playbook detects a bare-metal installation. It is mainly
  useful when installing under an hypervisor which is not currently
  supported. By default, the playbook would bail ouyt in such a case:
  skipping this tag force it to continue.

### Roles

The following sections give a brief description of available role. For
detailed explanation of each role configuration options, look at its own
defaults file.

For each role, a flag list is given according to the following
structure:

    [--]
     ││
     │├ s Can be called multiple times with different input variables
     │└ m Should be called just once. If called multiple times, it will
     │     either be idempotent or undo later modifications (i.e. if you
     │     create users with the `users` role, manually change passwords
     │     and call it again, the passwords will be reset.
     │
     ├─ - Can be used in both the bootstrap and mainconfig phases
     ├─ b Can only be used in the bootstrap phase
     └─ m Can only be used in the mainconfig phase

It is used to distingiush roles which only work in specific playbook
phases from those that can be used freely. Also, some roles are meant
to offer service to other roles (such as `packages`) while others
do more extensive setup and it makes no sense to call them multiple
times as they are idempotent (like `virtguest`).


#### base\_packages

Flags: `[bm]`

Installs the base packages to the system being provisioned via pacstrap.

#### bluetooth

Flags: `[ms]`

Installs packages required for Bluetooth functionalities.

#### clean

Flags: `[ms]`

Clean installation leftovers (such as package caches) and undos some
configuration for portable images.

#### configure

Flags: `[bs]`

Post-`bootstrap` minimal configuration of the installed system. Mainly,
it ensures that things like networking and ssh will start automatically
at boot time, so that Ansible can connect to the installed system after
reboot.

#### custom\_repos

Flags: `[-m]`

It is possible to add extra repositories or mirrors during the
installation process. They will persists in the final system if it is
not configured as a portable installation.

Both repositories and mirrors take precedence over those already
configured. This means that:

* additional repositories will take precedence over `core`, `extra` and
  other official ones, so they can be used to override some official
  package with a local version;
* additional mirrors will be placed at the beginning of the mirrorlist
  so that pacman tries them first, and then moves on to other mirrors if
  the are all unreachable.

It accepts a `state` variable, to be set to either `present` or
`absent`. `present` will add repository definitions to `pacman` files,
while `absent` will remove them.

#### genfstab

Flags: `[bs]`

Generates a `fstab` file from the mountpoints found under a directory
tree. A typical use is to call it from the postpartitioning phase of a
partitioning flow in order to generated the `fstab` corresponding to the
partitions used during the installation.

#### hostname

Flags: `[-s]`

Sets up the host information in various files, such as `/etc/hostname`
and `/etc/hosts`. The host domain is set to `localdomain`.

When invoked, a `chroot` variable can be specified, to indicate where
files holding host information are to be found. If not passed, the
current root is used.

#### locale

Flags: `[ms]`

Set system locale information, such as the keymap, the locale and the
character set, the timezone.

#### makepkg

Flags: `[mm]`

This helper role downloads PKGBUILD tarballs from the AUR, builds them
and installs the resulting package. It lacks any dependency resolution
capability or any other feature one would expect from any AUR helper,
that's why it is normally only used to install `yay`.

It accepts a `packages` variable, which should contain a (YAML) list of
packages to install. If a package has AUR dependencies, list them all,
with dependencies coming before dependants.

#### packages

Flags: `[mm]`

Installs packages fomr either the AUR or regular repos. It delegates the
job to `yay`.

It accepts a `packages` variable, which should contain a (YAML) list of
packages to install. Since it harnesses the full power of `yay`, you can
mix AUR and regular packages in the list and don't have to worry about
dependencies or ordering. This is the role to invoke when you need to
install additional stuff.

#### pacstrap

Flags: `[bm]`

Uses `pacstrap` to install stuff to a system under installation.

It accepts a `packages` variable, which should contain a (YAML) list of
packages to install. No AUR packages can be used here since `pacstrap`
only handled regular repositories.

#### partitioning

#### passwordless\_sudo\_user

Flags: `[ms]`

Creates a dedicated user which can call `sudo` without being asked for a
password. This user is used to build packages, since it can become root
to install missing dependencies and the built package.

A handler ensures that, at the end of the play, this user is eviced from
the system.

#### proxy

Flags: `[-s]`

Configures the system to use an HTTP(S) proxy. In particular:

* it stores proxy variables into a global shell profile, imported by all
  users when a login shell is run;
* configures `sudo` to preserve those variables;
* tells `pacman` to use `curl` to grab files. This was done in order to
  have better control over the download timeout: `pacman`'s built-in
  downloader will, by default, abort a download if no data are received
  for about 10 seconds. There is an option to disable this, but AFAIK,
  it can only be passed via the command line and cannot be configured
  via `pacman.conf`. When setting a custom downloader, conversely, you
  can specify the full command line, including timeout related options.
  This point is important because many corporate proxies will implement
  some store-check for malware-forward logic which can break the default
  `pacman` timeout.

#### syslinux

Flags: `[bs]`

Installs `syslinux` (more accurately, `extlinux`) as the bootloader for
the new system. It assumes a legacy BIOS system and MBR partition tables
for the disk where `/boot` resides.

It automatically tries to detect most things on its own. The
configureation file with boot entries is dynamically generated from the
kernels and initramfs files present under the new system's `/boot`, so
one does not have to list them explicitly.

Also, it detects which device nodes are involved by looking up device
nodes associated with the new system's root partition and `/boot`. The
root partition is used to extract the UUID that ends up in boot entries,
while the device mounted under `/boot` is used to install the IPL (the
code that goes into the MBR). For example, if `/boot` is mounted from
`/dev/sda3`, the IPL code will be installed to `/dev/sda`.

The only tunable parameter is given by the `ipl` variable, a boolean
which controls if the IPL code should be installed or not. By default it
is set to yes. It makes sense to disable it if you plan to chain-load
syslinux from a different bootloader.

#### ttf\_fonts

Flags: `[ms]`

Installs a bunch of extra fonts.

#### users

Flags: `[ms]`

This role creates user accounts, sets their passwords and makes them
able to use sudo, if appropriate. It should be a dependency of all those
roles which copy files to home dirs or expect users/home folders to
exist.

After execution, it will have defined two variables that can be used to
iterate over user information:

* `users_names` is a list holding all non-root accounts defined in the
  defaults (or overriden somewhere else);
* `users_created` is the output of the `user` Ansible module and
  contains useful info about created users, such as their home dirs. One
  can use them like this, to avoid assuming where home dirs are placed
  or their names (as we may allow setting home dir names in the future,
  rather than using the username):

```yaml
name: Copy a file to user home
copy:
  src: foobar
  dest: "{{ users_created | user_home(item) }}/.foobar"
loop: "{{ users_names }}"
```

Note that `user_home` is a custom filter that simply extracts the home
path for a user name.

Modules depending on `users` are allowed to access those two variables
as role output.

All user info (such as username, password, additional groups) is stored
into this module's defaults file. As usual, it can be overridden in host
or group variables.

#### utils

Flags: `[ms]`

Installs a bunch of CLI utils. This is where additional utils should be
added. If a tool depends on the X Window System somehow, it should go
under `xutils`.

#### virtguest and virtguest\_force

Flags: `[ms]`

These roles deal with VM-specific tweaks, like installing guest
additions.

By default, the playbook uses facts to detect if the target system is
running under an hypervisor. If so, some behaviour will be adjusted
accordingly: for example, guest additions are installed and enabled
automatically and the screensaver is disabled by default. If the
hypervisor is unsupported, the playbook bails out. To proceed under an
unsupported hypervisor without its additions, skip the `virtguest` tag.

`virtguest_force` can be used to override the detected hypervisor or to
force a bare-metal installation to be treated like a VM installation.
This is only useful should Ansible ever fail to correctly detect that we
are running under a VM, or misdetect the hypervisor.

`virtguest` takes care of doing the real work for the detected
hypervisor, as reported by Ansible and potentially overridden by
`virtguest_force`.

When installing under VirtualBox 6.0 and above, and the VM uses the
`VBoxVGA` adapter, automatic guest screen resizing will no longer work
reliably. As a workaround, `virtguest` can be instructed to install the
`mplugd` daemon, configured to handle screen resizing. You can read more
[here][mplugd-blog-post].

#### xfce

Flags: `[ms]`

Installs the XFCE desktop environment.

#### xfce\_user\_customizations

Flags: `[ms]`

This role does two things:

* it installs packages related to XFCE eyecandy (themes, icons,
  engines);
* copies configuration files to each user home folder, in order to set
  the default look and feel.

Tweak the defaults to select which themes are to be installed and which
should be used as the default for users. It currently not possible to
specify themes on a per-user basis.

#### xorg

Flags: `[ms]`

Installs the X Window System, specifically X.org.

This role is usually pulled in as a dependency of other roles which
install GUI applications, such as `xutils`.

#### xscreensaver

Flags: `[ms]`

Installs `xscreensaver`. This tool has been granted a role on its own,
rather than simply being another entry under `xutils`, because its
configuration depends on the installation type.

When doing bare-metal installations, the screensaver is enabled by
default and will lock the screen after a few minute of inactivity as a
security measure.

Conversely, VM installations will have it installed but disabled,
because one would assume that the host itself already has a screensaver
and there is no reason the get asked for two different password every
time the screen is locked.

The defaults provide a way to override this behaviour.

#### xutils

Flags: `[ms]`

Installs a bunch of GUI utils. This is where additional grtaphical utils
should be added. If a tool does not depend on the X Window System
somehow, it should go under `utils`.

#### yay

Flags: `[ms]`

Installs `yay` from the AUR.

#### yay\_user\_customizations

Flags: `[ms]`

Copies `yay` configuration files to each user's home directory. This
does not affect the use of the `packages` role, because it passes all
options explicitly on the command line. It is meant to provide
reasonable defaults to users which desire to use `yay` as their AUR
helper after the system has been installed.

## Simple customization

### Add a non-X11 package

If you want to add a new non-X11 package to every installation and it
does not require special configuration, copy the package list in
`roles/utils/meta/main.yaml` to a `group_vars` file and then customize
it. Your list will override the default.

### Add an X11 package

If you want to add a new X11 package to every installation and it does
not require special configuration, copy the package list in
`roles/xutils/meta/main.yaml` to a `group_vars` file and then customize
it. Your list will override the default.

### Add a package that requires configuration

If you want to add a new package to every installation and it
requires special configuration (i.e. configuration files to be copied),
create a new role for it that includes files and templates.

Delegate the actual installation to the `packages` role. AUR packages
are fine since `yay` is used. Then do the rest of the setup.

```yaml
- import_role:
    name: packages
    vars:
      packages:
        - my_package

- copy:
    src: my_package.conf
    dest: /etc/my_package.conf
```

This approach allows for the maximum flexibility (i.e. to install and
configure an additional DE). If the package requires X11, add the `xorg`
role to its dependencies.

## Side projects

This project comes with two side projects, designed to ease the
provisioning of VM's with Arch-Ansible. They rely on HashiCorp
[Vagrant](https://www.vagrantup.com/) and
[Packer](https://www.packer.io/) and can be found under the folders with
the corresponding names. For simplicity, I'll refer to them as
[Arch-Vagrant](vagrant/README.md) and [Arch-Packer](packer/README.md).
Click the links to read their own docs.

## Integration with pkgproxy

If you are going to do multiple installations using arch-ansible in a
short interval, it may be best to save and reuse downloaded packages
across runs.  To do that, the simplest way is to use the
[pkgproxy](https://github.com/buckket/pkgproxy) tool, which acts as a
cache between an Arch Linux mirror and your system.

It is very simple to use: you run it, configure it as a mirror for your
system, and every downloaded package will get stuffed into its cache.
arch-ansible has support for additional mirrors, so it is easy to tell
it to use your local pkgproxy instance by adding an extra file as
described in [Configuration](#Configuration). For example, you may add
the following contents to `group_vars/all/50-pkgproxy.yaml`:

    custom_repos_servers:
      - http://10.0.2.2:8080/$repo/os/$arch

The exact hostname and port will vary depending on where you run
pkgproxy. The example above assumes that Arch is running inside a VM,
while pkgproxy is running on the host, on port 8080.

## Bare metal installation

_NOTE: unless noted, all commands are intented to be run on the target
machine._

arch-ansible can provision physical machines, not just VM's. But some
care must be taken in preparing the host/group variables files, plus
some network-related actions. Also, you will need a separate PC to be
used as the Ansible controller, which must be able to connect to the
target machine.

_Note: before running the following steps, keep in mind that the
`bootstrap` tag enables tasks which will partition, format, and install
a new bootloader to your machine. This may cause data loss or require
you to reinstall your bootloader to get a preinstalled OS to boot
again._ Triple check the chosen disk and partition in the global
configuration. Rememeber that the IPL for that disk will be overwritten,
so if it already contains the loader for a different system, that system
will no longer boot after the installation. If possible, you can then
configure Syslinux to chainload the other system.


The target will be rebooted multiple times during the installation and
if you are using DHCP the IP may change across reboots. You may want to
configure your local DHCP server to give the target a fixed IP by using
a MAC address reservation.

When rebooting from the install media into the installed system, it
would be useful if the system firmware were configured to automatically
boot into the new system, otherwise the installation media would boot
again and the installation could not proceed.

The target will need to be accessible over SSH. Ensure that
`/etc/ssh/sshd_config` allows root login: it should contain the
following line:

    PermitRootLogin yes

Then give the root user a password:

    # passwd

And start SSH:

    # systemctl start sshd

At this point incoming connections are allowed, but it is better to let
SSH use a private key for authentication rather than a password. Let's
generate a new keypair (which can be reused across all installations;
note the `-N ''`, which means the private key is unencrypted so no
password is asked when connecting) and copy the public part to the
target:

    # On the controller
    $ ssh-keygen -N '' -f ~/.ssh/arch-install
    $ ssh-copy-id -i ~/.ssh/arch-install root@your.machine.local

Edit your `$HOME/.ssh/config` file to associate your target system with
this key:

    Host your.machine.local
    IdentityFile ~/.ssh/arch-install
    IdentitiesOnly yes

Edit the Ansible inventory file to point to the target machine.

Apply any other customization via host/group variables. And finally run:

    # On the controller
    $ ansible-playbook -i hosts.yaml --tags bootstrap,mainconfig site.yaml

After installation is complete, you can delete the key pair generated
above, from both the controller and the target.

[numix]: docs/numix.png
[darkblue]: docs/darkblue.png
[mplugd-blog-post]: https://binary-manu.github.io/binary-is-better/virtualbox/resize-vbox-screen-with-mplugd

<!-- vi: set tw=72 et sw=2 fo=tcroqan autoindent: -->
