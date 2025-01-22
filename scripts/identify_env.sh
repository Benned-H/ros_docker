#!/bin/bash

# Identify the local environment (Reference: https://stackoverflow.com/a/3466183)
# Possible outputs: LINUX_NVIDIA, LINUX, MACOS (exit 1 on error)
identify_env() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)     machine=Linux;;
        Darwin*)    machine=Mac;;
        *)          echo "Unsupported environment: ${unameOut}"; exit 1;;
    esac

    # Check for an NVIDIA GPU on any Linux host machine
    if [[ $machine == "Linux" ]]; then
        if lshw -C display 2>/dev/null | grep -q "NVIDIA"; then
            # Check that nvidia-smi works as expected
            if nvidia-smi &>/dev/null; then
                echo "LINUX_NVIDIA"
            else
                echo "Error: NVIDIA GPU detected, but nvidia-smi is not set up properly."
                exit 1
            fi
        else
            echo "LINUX"
        fi
    else
        echo "MACOS"
    fi
}
