# Arch-Ansible: a playbook to install Arch Linux

Arch-Ansible is a playbook designed to install Arch Linux on a target
machine. It was conceived to ease the preparation of virtual machines,
but could be used to install on bare metal, with some tweaks.

## Installed system

Unless some steps are skipped or customized, the installed system will
run XFCE with the Numix theme. No greeter is installed by default: each
user's `.xinitrc` is configured to launch XFCE when calling startx.

A bunch of default utilities like a PDF reader or gvim a preinstalled.
These are handled by the `utils` and `xutils` roles.

Users (including `root`) get their passwords from
`roles/users/defaults/main.yaml`. The file is stored in cleartext within
this repository to show its structure and allow modification. In real
scenarios, people should customize it and then encrypt it with
ansible-vault before committing to a VCS.

Currently only single-partition MBR installations are supported, using
syslinux as the bootloader. Swap space is not configured.

There is support for installing hypervisor guest additions as part of
the process.  This can be disabled by skipping the `virtguest` tag.  As
of today, only VirtualBox is supported.

The playbook relies on the [Yay](https://github.com/Jguer/yay) AUR
helper to install packages. Using `yay` instead of the stock `pacman`
module allows for uniform installation of binary and AUR packages. You
are free to uninstall `yay` after the provisioning is complete and to
install your favorite AUR helper.

## Playbook structure

The playbook is broken into two big parts, identified by tags:

* `bootstrap` is meant to run against a system running an Arch Linux
  installation media. It takes care of partitioning the disk, installing
  a bootloader and a set of base packages. Then reboot.
* `mainconfig` runs against the installed base system, adding additional
  packages, installing a DE, creating users and configuring locales. At
  the end, the system is read for use.

When used together, they build a complete system from an installation
media. `mainconfig` can also be run independently of `bootstrap`,
provided that the initial system state allows for Ansible incoming
connections.

This scenario could be used to provision an existing Vagrant box, for
which `bootstrap` would be of no use, since it is already partitioned
and base packages are installed. Some minor adjustments might be
required in this case (i.e. Vagrant boxes likely come with pre-installed
VirtualBox guest utilities without X support, which will cause
virtualbox-guest-utils not to install).

### bootstrap

The `bootstrap` phase can be tweaked by skipping tags:

* `partitioning` can be used to disable partitioning. It can be useful
  if a user wants to prepare a more complex layout by hand before
  launching the playbook. Once partitions have been mounted under a
  certain folder (typically `/mnt`) it makes no difference who mounted
  them;
* `bootloader` can be used to disable bootloader installation. Again,
  this may be useful if the user wants to customize the bootloader setup
  or use something different than syslinux.

Installation of base packages cannot be skipped, but it can be
customized by editing `roles/base_packages/defaults/main.yaml`. It
already contains a very minimal set of packages and there is no
advantage is adding additional tools here.

### mainconfig

This tag marks the tasks that does the heavy lifting. It configures
locales, creates users and sets their initial passwords, and prepare the
system to work behind a proxy. These steps are compulsory.

Additional steps include installing utilities and GUI apps, a desktop
environment and applying default customizations to users. These steps
can be skipped or selected one by one using tags:

* `virtguest` install hypervisor guest additions;
* `xfce` installs the XFCE DE plus some theme customizations for all
  non-root users;
* `yay` copies `yay` settings to each user home folder;
* `ttf_fonts` installs additional fonts;
* `utils` installs some non-X utilities (listed in
  `roles/utils/defaults/main.yaml`
* `xutils` installs some X utilities (listed in
  `roles/xutils/defaults/main.yaml`

Roles which install X apps will automatically pull X.org as a
dependency.

### Reboot

After both `bootstrap` and `mainconfig` the system will be rebooted to
ensure a clean start. This can be disabled by skipping the `reboot` tag.

### Force handlers to run again

If during execution, the playbook fails while executing a handler, the next
time it is run the handler will not run again, because the notifying task
will report an `ok` status.

As a workaround, you can force all handlers to run again by setting the
variable `run_handlers` to `true`. This works by causing all tasks that
trigger a handler to report a `changed` status.

It works differently than `--force-handlers`. As per Ansible documentation:

> When handlers are forced, they will run when notified even if a task fails
> on that host.

while, in our scenario, handlers would _not_ be notified by tasks when they
return `ok`.

## Configuration

By design, global configuration items are those which are used by multiple
roles and are stored in `group_vars/all/00-defaults.yaml`. Other variables,
which are local to a specific role, are stored under
`roles/$ROLE/defaults/main.yaml`. Both groups can be overridden by placing a
new file under `group_vars`, `host_vars` or using the command line. This way,
one can keep the default configuration and just change the target system
hostname or locale.

### Global configuration

The file `group_vars/all/00-default.yaml` contains global configuration
options that affect how the playbook work.

    global_device_node: /dev/sda
    global_partition_number: 1
    global_mount_point: /mnt

These options define the disk that will be used for partitioning during
the bootstrap phase, the index of the root partition, and the place
where the partitio is going to be mounted. If partitioning is skipped,
`global_mount_point` is still releevant because the user must manually
mount volumes there.

    global_admins:
      - manu

Initial users to create. They will all be added to the wheel group and
allowed to call sudo (with password). Password for individual users
(including root) can be set in `roles/users/defaults/main.yaml`.

    global_passwordless_sudo_user: package_builder

During certain tasks (such as when building packages from the AUR) the
playbook will need to drop privileges and use a non-root user, which
must be able to use sudo without a password. Think of a typical `makepkg
-s` call, which won't work as `root` but will then need to become root
to install dependencies.

This username is used to create a disposable nonprivileged user for
those tasks. All its data are automatically purged before the playbook
ends, so that there are no users with passwordless sudo capabilities on
the system, unless you create one.

    global_proxy_env: {
      # Uncomment the following definitions if behind a proxy
      # http_proxy: "http://your.proxy",
      # https_proxy: "http://your.proxy"
    }

If working behind a (HTTP(S)) proxy, uncomment the variable definitions.
This will automatically trigger proxy-related tasks and configure the
installed system to work behind a proxy (by setting appropriate
environment variables).

If using a direct connection, leave the `global_proxy_env` empty object
in place, as well as proxy-related tasks. They will be skipped
automatically.

### Role configuration

`roles/base_packages/defaults/main.yaml`

    base_packages_list:
      - base
      - base-devel
      - ...

List of base packages to be installed on the target system during the
`bootstrap` phase.

`roles/hostname/defaults/main.yaml`

    hostname_hostname: archlinux

Hostname information.

`roles/locale/defaults/main.yaml`

    locale_timezone: Europe/Rome
    locale_locale: it_IT.UTF-8
    locale_keymap: it

Locale information.

roles/makepkg/defaults/main.yaml

    makepkg_aur_url: https://aur.archlinux.org/cgit/aur.git/snapshot/

URL from which AUR packages are downloaded.

`roles/ttf_fonts/defaults/main.yaml`

    ttf_fonts_packages:
      - ttf-bitstream-vera
      - ttf-dejavu
      - ...

Packages installed by the `ttf_fonts` role.

`roles/users/defaults/main.yaml`

    users_info:
      root:
        password: "..."
      manu:
        password: "..."

Passwords for new users created on the target system. This should contain
passwords for all users defined in `global_admins`.

`roles/utils/defaults/main.yaml`

    utils_packages:
      - ntfs-3g
      - p7zip
      - ...

Packages installed by the `utils` role.

`roles/virtguest/defaults/main.yaml`

    virtguest_force: ""

    virtguest_supported_hypervisors:
      - virtualbox

    virtguest_virtualbox_packages:
      - linux-headers
      - virtualbox-guest-utils

By default, the role uses facts to detect if the target system is
running under an hypervisor. For bare metal installations, no additional
steps are takes.  Under a supported hypervisor, guest additions are
installed and enabled automatically. If the hypervisor is unsupported,
the playbook bails out. To proceed under an unsupported hypervisor
without its additions, skip the `virtguest` tag.

Set `virtguest_force` to one of the members of
`virtguest_supported_hypervisors` to force the installation of the
corresponding additional packages. This may be useful in two cases:

- Ansible's setup module misdetects the hypervisor for whatever reason;
- the user wants to install guest packages that do not correspond to the
  detected hypervisor.

`roles/xfce/defaults/main.yaml`

    xfce_packages:
      - xfce4
      - xfce4-goodies

Packages installed by the `xfce` role.

`roles/xfce_user_customizations/defaults/main.yaml`

    xfce_user_customizations_packages:
      - gtk-engine-murrine
      - numix-gtk-theme
      - ...

Packages installed by the `xfce_user_customizations` role.

`roles/xorg/defaults/main.yaml`

    xorg_packages:
      - xorg
      - xorg-apps
      - ...

Packages installed by the `xorg` role. These are pulled as dependencies by
`xutils` and other roles that depend on a working X11 environment.

`roles/xutils/defaults/main.yaml`

    xutils_packages:
      - gvfs
      - udisks2
      - ...

Packages installed by the `xutils` role.

## Simple customization

### Add a non-X11 package

If you want to add a new non-X11 package to every installation and it does
not require special configuration, add it to the package list in
`roles/utils/meta/main.yaml`.

### Add an X11 package

If you want to add a new X11 package to every installation and it does not
require special configuration, add it to the package list in
`roles/xutils/meta/main.yaml`.

### Add a package that requires configuration

If you want to add a new package to every installation and it
requires special configuration (i.e. configuration files to be copied),
create a new role for it hat include files and templates.

Delegate the actual installation to the `packages` role. AUR packages
are fine since yay is used.

    import_role:
      name: packages
      vars:
        packages:
          - new_package_1
          - new_package_2

This approach allows for the maximum flexibility (i.e. to install and
configure an additional DE). If the package requires X11, add the `xorg`
role to its dependencies.

## Running the playbook against the installation media

Here I assume you want to create a VM using VirtualBox. The entire
playbook will be used (including the bootstrap phase).

1. Download the latest Arch Linux installation media;
1. create a new VirtualBox machine with the desired configuration. Since
   the final system is going to be a GUI system, it is probably a good
   idea to:

   * give it at least 1GiB of RAM;
   * give it at least 16MiB of video RAM.

   Also, I suggest to leave the internal disk as the default boot media,
   so that the new installed system will boot after the system is
   restarted;
1. ensure that Ansible will be able to connect to the machine. The
   simplest way is to give it a NAT adapter and configure port
   forwarding from a local port to SSH (i.e. 2222 -> 22);
1. boot the machine;
1. start `sshd` and set a password for root;
1. customize the playbook configuration (inventory and group\_vars);
1. run the playbook. Use the `-k` option to force Ansible to ask for the
   SSH password.

<!-- vi: set tw=72 et sw=2 fo=tcroqan autoindent: -->
