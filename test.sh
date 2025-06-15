#!/bin/bash

export ARCH_ANSIBLE_LIBVIRT_USER_SESSION=1
export ARCH_ANSIBLE_HEADLESS=1

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

cleanup_virtualbox() {
    echo "Deleting all existing VirtualBox VMs..."
    VBoxManage list vms |
        sed 's/.*{\([-[:xdigit:]]\+\)}$/\1/' |
        xargs -I% sh -c "VBoxManage controlvm % poweroff; sleep 3; VBoxManage unregistervm % --delete"
}

cleanup_virsh() { (

    export VIRSH_DEFAULT_CONNECT_URI='qemu:///system'
    if [ -n "$ARCH_ANSIBLE_LIBVIRT_USER_SESSION" ]; then
        VIRSH_DEFAULT_CONNECT_URI='qemu:///session'
    fi

    echo "Deleting existing virsh VMs..."
    virsh list --all --name |
        xargs -I% sh -c "virsh destroy %; sleep 3; virsh undefine % --nvram --remove-all-storage"
); }

cleanup_override_files() {
    echo "Cleaning existing override files..."
    rm -f ansible/group_vars/all/9*.yaml
}

add_ansible_variables() {
    echo "Adding Ansible variables for testing..."
    cat <<EOL > ansible/group_vars/all/90-ci-defaults.yaml
global_portable_image: true
bluetooth_override: active
xfce_user_customizations_kvantum_theme: KvAdaptaDark
xscreensaver_override: active
i3wm_enabled: true
i3wm_screensaver_override: active
i3wm_compositor_override: active
EOL
}

colorful_status() {
    if [ "$1" -eq 0 ]; then
        echo -e " ${GREEN}PASS${NC}"
    else
        echo -e " ${RED}FAIL${NC}"
    fi
}

perform_system_installation() { (
    local disksetup="$1"
    local provider="$2"
    echo "disksetup_roles_prefix: $disksetup" > ansible/group_vars/all/91-ci-disksetup.yaml

    local disksetup_escaped="$(echo "$disksetup" | tr / _)"

    echo "Starting installation test. To see the full log, tail test-packer-$provider-$disksetup_escaped.log"
    echo -n "Testing packer/$provider+$disksetup..."

    cd packer || exit
    ./packer-wrapper.sh build -only="$provider" -timestamp-ui packer-template.json &> ../"test-packer-$provider-$disksetup_escaped.log"
    
    colorful_status "$?"
); }

bring_vagrant_up() { (
    local provider="$1"
    echo "Starting provisioning test. To see the full log, tail test-vagrant-$provider.log"
    echo -n "Testing vagrant/$provider..."
    cd vagrant || exit
    vagrant up --provider "$provider" &> ../"test-vagrant-$provider.log"
    colorful_status "$?"
    vagrant halt
); }

clean() {
    cleanup_virtualbox
    cleanup_virsh
    cleanup_override_files
}

clean_and_prepare() {
    clean
    add_ansible_variables
}

# Esecuzione di Vagrant per diversi provider
declare -a providers=("virtualbox" "libvirt")

for provider in "${providers[@]}"; do
    clean_and_prepare
    bring_vagrant_up "$provider"
    echo "RESULT -> Vagrant ($provider) = OK"
done

# Esecuzione dei test per diverse configurazioni
declare -a configs=(
    "disksetup/mbr_singlepart/ virtualbox-iso"
    "disksetup/mbr_lvm qemu/"
    "disksetup/bios_gpt_btrfs/ virtualbox-iso"
    "disksetup/gpt_singlepart/ virtualbox-uefi"
)

for config in "${configs[@]}"; do
    clean_and_prepare
    perform_system_installation $config
    echo "RESULT -> Packer ($config) = OK"
done
