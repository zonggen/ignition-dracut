#!/bin/bash
set -euo pipefail

cmdline=( $(</proc/cmdline) )

# finds ostree= inside /proc/cmdline
cmdline_arg_ostree() {
    name="ostree" value=""
    for arg in "${cmdline[@]}"; do
        if [[ "${arg%%=*}" == "${name}" ]]; then
            value="${arg#*=}"
            break
        fi
    done
    echo "${value}"
}

# finds refspec= inside $(realpath /sysroot$(cmdline_arg_ostree)).origin
origin=$(realpath /sysroot$(cmdline_arg_ostree)).origin
cmdline_arg_refspec() {
    name="refspec" value=""
    for arg in "${origin[@]}"; do
        if [[ "${arg%%=*}" == "${name}" ]]; then
            value="${arg#*=}"
            break
        fi
    done
    echo "${value}"
}

# finds name value pair inside /proc/cmdline
cmdline_arg() {
    local name="$1" value="$2"
    for arg in "${cmdline[@]}"; do
        if [[ "${arg%%=*}" == "${name}" ]]; then
            value="${arg#*=}"
        fi
    done
    echo "${value}"
}

# copied from ignition-generator for testing
cmdline_bool() {
    local value=$(cmdline_arg "$@")
    case "$value" in
        ""|0|no|off) return 1;;
        *) return 0;;
    esac
}


# Checks if kernel argument directory exists,
# then redeploy and reboot the system if it exists
reboot_if_kargs_dir_exists() {

    # echo "*******************************************"
    # # echo "ls /sysroot/ostree: $(ls /sysroot/ostree)"
    # # echo "ls / $(ls /)"
    # ostree admin --sysroot=/sysroot status
    # echo "testfile: $(cat /sysroot/etc/ostree/kargs.d/testfile)"
    # echo "*******************************************"

    local REFSPEC=( $(ostree refs --repo /sysroot/ostree/repo) )

    if [ -d /sysroot/etc/ostree/kargs.d ]; then
        local kargs=$(cat /sysroot/etc/ostree/kargs.d/testfile)
        # ostree admin --sysroot=/sysroot --os=fcos deploy ${REFSPEC}
        echo "ls /sysroot/ostree/deploy/ $(ls /sysroot/ostree/deploy/)"
        ostree admin -v --sysroot=/sysroot instutil set-kargs --replace ${kargs}
        exec systemctl reboot
    fi
}

if $(cmdline_bool 'ignition.firstboot' 0); then
    reboot_if_kargs_dir_exists
fi
