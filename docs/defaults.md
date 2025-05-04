---
layout: default
title: Defaults files index
---
# Defaults files index

* [group_vars/all/00-default.yaml](#group_varsall00-defaultyaml)
* [roles/base_packages/defaults/main.yaml](#rolesbase_packagesdefaultsmainyaml)
* [roles/bluetooth/defaults/main.yaml](#rolesbluetoothdefaultsmainyaml)
* [roles/custom_repos/defaults/main.yaml](#rolescustom_reposdefaultsmainyaml)
* [roles/de_eyecandy/defaults/main.yaml](#rolesde_eyecandydefaultsmainyaml)
* [roles/disksetup/bios_gpt_btrfs/partitioning/defaults/main.yaml](#rolesdisksetupbios_gpt_btrfspartitioningdefaultsmainyaml)
* [roles/disksetup/defaults/main.yaml](#rolesdisksetupdefaultsmainyaml)
* [roles/disksetup/gpt_singlepart/partitioning/defaults/main.yaml](#rolesdisksetupgpt_singlepartpartitioningdefaultsmainyaml)
* [roles/disksetup/mbr_lvm/partitioning/defaults/main.yaml](#rolesdisksetupmbr_lvmpartitioningdefaultsmainyaml)
* [roles/disksetup/mbr_singlepart/partitioning/defaults/main.yaml](#rolesdisksetupmbr_singlepartpartitioningdefaultsmainyaml)
* [roles/hostname/defaults/main.yaml](#roleshostnamedefaultsmainyaml)
* [roles/i3wm/defaults/main.yaml](#rolesi3wmdefaultsmainyaml)
* [roles/locale/defaults/main.yaml](#roleslocaledefaultsmainyaml)
* [roles/makepkg/defaults/main.yaml](#rolesmakepkgdefaultsmainyaml)
* [roles/passwordless_sudo_user/defaults/main.yaml](#rolespasswordless_sudo_userdefaultsmainyaml)
* [roles/ttf_fonts/defaults/main.yaml](#rolesttf_fontsdefaultsmainyaml)
* [roles/users/defaults/main.yaml](#rolesusersdefaultsmainyaml)
* [roles/utils/defaults/main.yaml](#rolesutilsdefaultsmainyaml)
* [roles/virtguest/defaults/main.yaml](#rolesvirtguestdefaultsmainyaml)
* [roles/virtguest_force/defaults/main.yaml](#rolesvirtguest_forcedefaultsmainyaml)
* [roles/wireless/defaults/main.yaml](#roleswirelessdefaultsmainyaml)
* [roles/xfce/defaults/main.yaml](#rolesxfcedefaultsmainyaml)
* [roles/xfce_user_customizations/defaults/main.yaml](#rolesxfce_user_customizationsdefaultsmainyaml)
* [roles/xorg/defaults/main.yaml](#rolesxorgdefaultsmainyaml)
* [roles/xscreensaver/defaults/main.yaml](#rolesxscreensaverdefaultsmainyaml)
* [roles/xutils/defaults/main.yaml](#rolesxutilsdefaultsmainyaml)

## group_vars/all/00-default.yaml

```yaml
# Define the environment, then filter omitted fields. This is important so that
# undefined variables do not pop up in process environments. To override this
# settings, add a definition for specific fields (i.e. http_proxy), do not
# override either object.
global_proxy_env_:
  http_proxy: "{{ '{{' }} http_proxy | default(omit, true) }}"
  https_proxy: "{{ '{{' }} https_proxy | default(omit, true) }}"
  no_proxy: "{{ '{{' }} no_proxy | default(omit, true) }}"
global_proxy_env : "{{ '{{' }} global_proxy_env_ | dict2items |
  selectattr('value', 'ne', omit) | list | items2dict }}"

# After everything is done, remove settings which would cause the image to be
# non-portable to other systems. Currently this means removing cusom repos and
# proxy settings.
global_portable_image: False
```

## roles/base_packages/defaults/main.yaml

```yaml
base_packages_list:
  # Arch's base packages
  - base
  - base-devel
  # These packages used to be included in the "base" group. Now they must be
  # installed explicitly. Note that I just diffed what the base group included
  # against the direct dependencies of the base package, so it is likely that
  # some of these packages are already pulled in by base.
  - cryptsetup
  - device-mapper
  - dhcpcd
  - e2fsprogs
  - inetutils
  - jfsutils
  - linux
  - linux-firmware
  - logrotate
  - lvm2
  - man-db
  - man-pages
  - mdadm
  - nano
  - netctl
  - perl
  - sysfsutils
  - texinfo
  - usbutils
  - vi
  - xfsprogs
  # Additional tools needed to run Ansible and get network connectivity
  # after we reboot
  - sudo
  - networkmanager
  - openssh
  - python3
```

## roles/bluetooth/defaults/main.yaml

```yaml
# Controls if Bluetooth support is installed or not:
#
# * leave it empty to use the default behaviour, which installs
#   BT on bare metal systems only;
# * set to `active` to force installation even under hypervisors;
# * set to `inactive` to disable BT support.
#
# Other values are errors, and supported values are case-sensitive.
bluetooth_override: ""
```

## roles/custom_repos/defaults/main.yaml

```yaml
# Add extra repositories (i.e. like `core` and `community`.
# They will be added to `pacman.conf` _before_ standard repos, so
# that packages with the same name as standard ones will take
# precedence.
custom_repos_list: [
#  {
#    name: myrepo,
#    server: "http://10.0.2.2/x86_64/",
#    siglevel: Optional TrustAll
#  }
]

# Add extra mirrors to the mirrorlist. They are added _before_ other
# entries, so they will be tried first. They are inserted in the same
# order as they are listed here.
custom_repos_servers: [
#  "http://localhost:8080/$repo/os/$arch"
]
```

## roles/de_eyecandy/defaults/main.yaml

```yaml
# Additional packages to be installed for the Numix theme
de_eyecandy_packages_numix:
  - gtk-engine-murrine
  - numix-gtk-theme-git
  - numix-cursor-theme-git
  - numix-icon-theme-git
  - numix-square-icon-theme-git

# Additional packages to be installed for the DarkBlue theme
de_eyecandy_packages_darkblue:
  - gtk-engine-murrine
  - numix-themes-darkblue
  - numix-cursor-theme-git
  - kora-icon-theme

de_eyecandy_packages_equilux:
  - equilux-theme
  - kora-icon-theme

de_eyecandy_packages_dracula:
  - unzip

de_eyecandy_dracula_gtk: https://github.com/dracula/gtk/archive/master.zip
de_eyecandy_dracula_icons: https://github.com/dracula/gtk/files/5214870/Dracula.zip

# This controls which themes are installed (`installed: true`) and which one
# will be configured as the default for all non-root users (`default: true`).
# The `theme` corresponds to the name of a task file under `tasks/`.
# Only one theme should have `default` set, otherwise it is undefined behaviour
# whether an error is thrown or one of them is effectively set as the default.
# `installed` and `default` can be omitted and default to `false`.
de_eyecandy_themes:
  - theme: numix
    installed: true
  - theme: darkblue
    installed: true
    default: true
  - theme: equilux
    installed: true
  - theme: dracula
    installed: true

# If not empty, install kvantum and set the theme to the value of the variable.
# Also, add QT_STYLE_OVERRIDE=kvantum to the user's profile
de_eyecandy_qt_theme: "KvFlat"
```

## roles/disksetup/bios_gpt_btrfs/partitioning/defaults/main.yaml

```yaml
##### Public variables used by the rest of the playbook #####
partitioning_root_mount_point: "/mnt"

##### Private variables used only by the partitioning roles #####

# On this device node, two partitions will be created:
# * /dev/xxx1 will be used as the BIOS boot partition
# * /dev/xxx2 will be used as /
partitioning_priv_device_node: "/dev/sda"

# Offsets where partition starts, in bytes
partitioning_priv_start_offset: "{{ '{{' }} 1024 * 1024 }}"

# Size of the BIOS boot partition, in bytes
partitioning_priv_bios_part_size: "{{ '{{' }} 1024 * 1024 }}"

# Subvolumes are laid out in a flat fashion and named following snapper naming
# conventions:
#
# toplevel         (default subvolume, not mounted)
#   +-- @          (to be mounted at /)
#   +-- @snapshots (to be mounted at /.snapshots)
#   +-- @home      (to be mmounted at /home)
#   +-- ...
#
partitioning_priv_subvolumes: "{{ '{{' }} partitioning_priv_core_subvolumes + partitioning_priv_extra_subvolumes }}"

# You can add other subvolumes here, just add an @ at the beginning and
# keep them in mount order, By default /home gets its own subvolume.
partitioning_priv_extra_subvolumes:
  - name: "@home"
    mountpoint: /home

# These subvolumes should always be present. Do not override.
partitioning_priv_core_subvolumes:
  - name: "@"
    mountpoint: /
  - name: "@snapshots"
    mountpoint: /.snapshots
```

## roles/disksetup/defaults/main.yaml

```yaml
disksetup_roles_prefix: disksetup/mbr_singlepart/

disksetup_supported_apis:
    - partitioning.arch-ansible/v1
```

## roles/disksetup/gpt_singlepart/partitioning/defaults/main.yaml

```yaml
##### Public variables used by the rest of the playbook #####
partitioning_root_mount_point: "/mnt"

##### Private variables used only by the partitioning roles #####

# On this device node, two partitions will be created:
# * /dev/xxx1 will be used as /boot/efi
# * /dev/xxx2 will be used as /
partitioning_priv_device_node: "/dev/sda"

# The ESP partition will be this large, in bytes (plus any alignment
# constraint)
partitioning_priv_esp_size: "{{ '{{' }} 512 * 1024 * 1024 }}"
```

## roles/disksetup/mbr_lvm/partitioning/defaults/main.yaml

```yaml
##### Public variables used by the rest of the playbook #####
partitioning_root_mount_point: "/mnt"

##### Private variables used only by the partitioning roles #####

# On this device node, two partitions will be created:
# * /dev/xxx1 will be used as /boot
# * /dev/xxx2 will be used as a PV to host /
partitioning_priv_device_node: "/dev/sda"

# The boot partition will be this large, in bytes (plus any alignment
# constraint)
partitioning_priv_boot_size: "{{ '{{' }} 512 * 1024 * 1024 }}"

# Names for the VG and LV
partitioning_priv_vg_name: "arch"
partitioning_priv_lv_name: "root"
```

## roles/disksetup/mbr_singlepart/partitioning/defaults/main.yaml

```yaml
##### Public variables used by the rest of the playbook #####
partitioning_root_mount_point: "/mnt"

##### Private variables used only by the partitioning roles #####
partitioning_priv_root_device_node: "/dev/sda1"
```

## roles/hostname/defaults/main.yaml

```yaml
# The installed system's hostname, as configured in `/etc/hostname` and
# `/etc/hosts` for the loopback address. _Do not_ add the domain part.
hostname_hostname: archlinux
```

## roles/i3wm/defaults/main.yaml

```yaml
# List of packages to be installed if i3wm_enabled is true
i3wm_packages:
  - i3-wm
  - i3status
  - i3-exitx-systemd-git
  - dex
  - pasystray
  - tilix
  - rofi
  - mate-polkit
  - pcmanfm-gtk3
  - ttf-ubuntu-font-family
  - ttf-sourcecodepro-nerd
  - dunst
  - seahorse

# Set either values to "active" to force starting the screensaver/compositor
# when i3 starts. Set it to "inactive" to keep them off. Leave blank to use a
# fact-based choice: on on physical machines, off in VMs.
i3wm_screensaver_override: ""
i3wm_compositor_override: ""

# Inactivity timer after which the screen will be powered off and blocked by
# xsecurelock.
i3wm_screensaver_timeout_in_secs: 180
```

## roles/locale/defaults/main.yaml

```yaml
locale_timezone: Europe/Rome
locale_locale: it_IT.UTF-8
locale_keymap: it
```

## roles/makepkg/defaults/main.yaml

```yaml
# When downloading PKGBUILD tarball snapshots from the AUR, this
# URL is used.
makepkg_aur_url: https://aur.archlinux.org/cgit/aur.git/snapshot/
```

## roles/passwordless_sudo_user/defaults/main.yaml

```yaml
# This user will be created during the setup to build AUR packages, and will be
# removed before finalizing the installation.
passwordless_sudo_user_name: sudonopw
```

## roles/ttf_fonts/defaults/main.yaml

```yaml
# A list of font packages to install. Both AUR and regular packages can be
# supplied here.
ttf_fonts_packages:
  - ttf-bitstream-vera
  - ttf-dejavu
  - ttf-droid
  - ttf-inconsolata
  - ttf-liberation
  - ttf-ubuntu-font-family
  - noto-fonts-emoji
```

## roles/users/defaults/main.yaml

```yaml
# All user information pertaining to root. For the moment there's just the
# password.
users_root_info:
    password: "abcd$1234_root"

# User info for all non-root users.
#
# The dictionary name (i.e. manu) is used as the user name.
#
# Users with `is_admin` set to true will be able to call sudo to perform any
# task as root, with their password asked.
#
# Additional groups can be added via the `groups` list. To make a user
# sudo-enabled, set `is_admin` to true, _do not_ add `wheel` to `groups`.
users_info:
  manu:
    password: "abcd$1234_manu"
    is_admin: true # Optional item, true if missing
    groups: []     # Optional item, empty list if missing

# Apply a patch to PAM configuration to avoid locking accounts in face of
# authentication errors that do not imply a wrong password.
users_fixup_faillock: no
```

## roles/utils/defaults/main.yaml

```yaml
# A list of non-GUI packages to install. Both AUR and regular packages can be
# supplied here.
utils_packages:
  - ntfs-3g
  - p7zip
  - rsync
  - hexer
  - net-tools
  - iotop
  - pulseaudio
  - pulseaudio-alsa
```

## roles/virtguest/defaults/main.yaml

```yaml
# The list of currently supported hypervisors
virtguest_supported_hypervisors:
  - virtualbox
  - kvm

# Packages to install to add VirtualBox support to the VM
virtguest_virtualbox_packages:
  - virtualbox-guest-utils
```

## roles/virtguest_force/defaults/main.yaml

```yaml
# Set this to a value from virtguest_supported_hypervisors
# to force the corresponding backend to be invoked
virtguest_force: ""
```

## roles/wireless/defaults/main.yaml

```yaml
# Leave empty to use the same country specified for the locale.  Otherwise,
# specify an ISO 3166-1 alpha-2 country code; for example:
#
# wireless_regdom_country: "IT"
wireless_regdom_country: ""
```

## roles/xfce/defaults/main.yaml

```yaml
xfce_packages:
  - xfce4
  - xfce4-goodies
```

## roles/xfce_user_customizations/defaults/main.yaml

```yaml
# Additional packages to be installed for the Numix theme
xfce_user_customizations_packages_numix:
  - gtk-engine-murrine
  - numix-gtk-theme-git
  - numix-cursor-theme-git
  - numix-icon-theme-git
  - numix-square-icon-theme-git

# Additional packages to be installed for the DarkBlue theme
xfce_user_customizations_packages_darkblue:
  - gtk-engine-murrine
  - numix-themes-darkblue
  - numix-cursor-theme-git
  - kora-icon-theme

xfce_user_customizations_packages_equilux:
  - equilux-theme
  - kora-icon-theme

xfce_user_customizations_packages_dracula:
  - unzip

xfce_user_customizations_dracula_gtk: https://github.com/dracula/gtk/archive/master.zip
xfce_user_customizations_dracula_icons: https://github.com/dracula/gtk/files/5214870/Dracula.zip

# This controls which themes are installed (`installed: true`) and which one
# will be configured as the default for all non-root users (`default: true`).
# The `theme` corresponds to the name of a task file under `tasks/`.
# Only one theme should have `default` set, otherwise it is undefined behaviour
# whether an error is thrown or one of them is effectively set as the default.
# `installed` and `default` can be omitted and default to `false`.
xfce_user_customizations_themes:
  - theme: numix
    installed: true
  - theme: darkblue
    installed: true
    default: true
  - theme: equilux
    installed: true
  - theme: dracula
    installed: true

# If not empty, install kvantum and set the theme to the value of the variable.
# Also, add QT_STYLE_OVERRIDE=kvantum to the user's profile
xfce_user_customizations_kvantum_theme: ""
```

## roles/xorg/defaults/main.yaml

```yaml
xorg_packages:
  - xorg
  - xorg-apps
  - xorg-drivers
  - xorg-apps
  - xorg-fonts
  - xorg-xinit

```

## roles/xscreensaver/defaults/main.yaml

```yaml
# Set to:
# * `active` to force the screensaver to be enabled after installation
# * `inactive` to force the screensaver to be disabled after installation
# * Empty to preserve the default behaviour (fact-based choice): the
#   screensaver will be enabled by default on bare metal systems and
#   disabled in VM's.
# This only changes xscreensaver configuration, the program itself is
# always installed.
xscreensaver_override: ""
```

## roles/xutils/defaults/main.yaml

```yaml
# A list of GUI packages to install. Both AUR and regular packages can be
# supplied here. X.org is already pulled in as a dependency.
xutils_packages:
  - gvfs
  - udisks2
  - file-roller
  - evince
  - gnome-calculator
  - gnome-keyring
  - gvim
  - network-manager-applet
  - nm-connection-editor
  - firefox
  - filezilla
  - x11-ssh-askpass
  - pavucontrol
```
