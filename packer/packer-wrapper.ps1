# Set strict mode
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Function to check if VBoxManage supports --nat-localhostreachableN
function CheckNatLocalhost {
    $vboxHelp = & VBoxManage --help
    if ($vboxHelp -match "--nat-localhostreachableN") {
        $Env:ARCH_ANSIBLE_PACKER_VBOX_NAT_LOCALHOST_KEY = "--nat-localhostreachable1"
        $Env:ARCH_ANSIBLE_PACKER_VBOX_NAT_LOCALHOST_VAL = "on"
    } else {
        $Env:ARCH_ANSIBLE_PACKER_VBOX_NAT_LOCALHOST_KEY = "--nic1"
        $Env:ARCH_ANSIBLE_PACKER_VBOX_NAT_LOCALHOST_VAL = "nat"
    }
}

# Check for VBoxManage support for --nat-localhostreachableN
CheckNatLocalhost

# For backward compatibility, set headless mode unless overridden
if ($Env:ARCH_ANSIBLE_HEADLESS) {
    $Env:ARCH_ANSIBLE_PACKER_HEADLESS = "true"
} else {
    $Env:ARCH_ANSIBLE_PACKER_HEADLESS = "false"
}

# Set number of CPUs
if ($Env:ARCH_ANSIBLE_CPUS) {
    $Env:ARCH_ANSIBLE_PACKER_CPUS = $env:ARCH_ANSIBLE_CPUS
} else {
    $Env:ARCH_ANSIBLE_PACKER_CPUS = 1
}

# Call Packer with arguments
& packer $args
